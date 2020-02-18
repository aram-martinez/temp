require 'json'
require 'digest'
require 'openssl'
require 'net/http/post/multipart'

# Para encriptar contraseñas e información de la tarjeta se debe utilizar el 
# RequestKey y el RequestIV
# Para el header 'x-requested-with se debe utilizar el 
# RequestSignatureKey y el RequestSignatureIv
module Feenicia
  # Constantes de Impuestos utilizadas por Feenicia
  class Impuesto
    MORAL = "1"
    FISICA = "2"
  end

  # Constantes de Archivos utilizadas por Feenicia
  class Archivo
    IDENTIFICACION = "CONT"
    RFC = "RFC"
    ACTA = "ACTC"
    DOMICILIO = "DOMC"
    CUENTA = "CTAB"
  end

  #Clase para relizar una venta (pago de factura) en feenicia, aqui son requeridos los datos del merchant (credenciales y que tambien ya este dado de alta en feenicia (aprobado))
  #merchant es un objeto tipo FeeniciaMerchant(falta crear modelo y tabla)
  class VentaManual

    attr_accessor :request_key, :request_iv, :request_signature_key, :request_signature_iv, :response_key, :response_iv, :response_signature_key, :response_signature_iv, :merchant_numero, :merchant_usuario, :merchant_afiliacion, :empresa, :factura, :tarjeta, :info_transaccion

    def initialize(merchant, empresa_feenicia, empresa, factura, tarjeta)
      #Datos del merchant
      self.merchant_numero = merchant.merchant_feenicia
      self.merchant_usuario = merchant.user_feenicia
      self.merchant_afiliacion = merchant.affiliation_feenicia
      #Llaves del Merchant (Request, Response)
      self.request_key = merchant.request_key
      self.request_iv = merchant.request_iv
      self.request_signature_key = merchant.request_signature_key 
      self.request_signature_iv = merchant.request_signature_iv
      self.response_key = merchant.response_key
      self.response_iv = merchant.response_iv
      self.response_signature_key = merchant.response_signature_key 
      self.response_signature_iv = merchant.response_signature_iv
      self.empresa = empresa
      self.factura = factura
      self.tarjeta = tarjeta
      self.info_transaccion = Hash.new
    end

    #Se envian los datos de la factura que se quiere "cobrar" y los datos del emisor (merchant_feenicia)   => Retorna un OrderID
    def generar_venta
      endpoint = "/receipt/order/create"
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv

      json = {
        amount: factura.total.to_f,
        items: [
          Quantity: "1",
          description: "Factura #{factura.serie}-#{factura.folio}",
          unitPrice: factura.total.to_s,
          amount: factura.total.to_f,
          Id: 0
        ],
        merchant: self.merchant_numero,
        userId: self.merchant_usuario
      }

      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, self.merchant_numero)

      #Agrega empresa_id y factura_id a info transaccion
      self.info_transaccion[:empresa_id] = self.empresa.id
      self.info_transaccion[:factura_id] = self.factura.factura_id

      if response[:error] == false
        
        respuesta = JSON.parse(response[:response])
        feenicia_log("crear_orden", json.to_json, respuesta)
        #Si se creó la orden, realizamos la venta
        if respuesta["responseCode"] == "00"
          id_orden = respuesta["orderId"]
          self.info_transaccion[:orderId] = id_orden
          realizar_venta(id_orden)
        else
          return {error: true, mensaje: "Ocurrió un error al crear la orden"}
        end
      else
        return {error: true, mensaje: "Ocurrió un error al crear la orden"}
      end
    end

    #Metodo para realizar el pago de un OrderID, es cuando se realiza el pago, se debe enviar to
    def realizar_venta(order_id)
      endpoint = "/v1/atna/sale/manual"
      # endpoint = "/atena-swa-services-0.1/sale/manual"
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv

      json = {
        affiliation: self.merchant_afiliacion,
        amount: factura.total.to_f,
        transactionDate: DateTime.now.strftime('%Q'),
        orderId: order_id,
        tip: 0,
        pan: encriptar_sensible(tarjeta[:tarjeta]),
        cardholderName: encriptar_sensible(tarjeta[:nombre]),
        cvv2: encriptar_sensible(tarjeta[:cvv]),
        expDate: encriptar_sensible(tarjeta[:vencimiento])
      }

      #Guardar el numero de recibo en info_transaccion
      self.info_transaccion[:transactionDate] = DateTime.now

      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, self.merchant_numero)

      if response[:error] == false
        respuesta = JSON.parse(response[:response])
        feenicia_log("realizar_venta", json.to_json, respuesta)
        #Si se realizó la venta, la guardamos
        if respuesta["responseCode"] == "00"
          info = {
            orderId: order_id,
            transactionId: respuesta["transactionId"],
            authnum: respuesta["authnum"],
            panTermination: respuesta["card"]["last4Digits"]
          }

          #Registrar datos de la transaccion
          self.info_transaccion[:transactionId] = respuesta["transactionId"]
          self.info_transaccion[:authnum] = respuesta["authnum"]
          self.info_transaccion[:last4Digits] = respuesta["card"]["last4Digits"]
          self.info_transaccion[:affiliation] = respuesta["affiliation"]

          guardar_venta(info)
        else
          return {error: true, mensaje: "Ocurrió un error al realizar la venta"}
        end
      else
        return {error: true, mensaje: "Ocurrió un error al realizar la venta"}
      end

    end

    def guardar_venta(info)
      endpoint= "/receipt/signature/save"
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv
      order = info[:orderId]
      transaction = info[:transactionId]

      json= {
        orderId: order,
        transactionId: transaction,
        authnum: info[:authnum],
        transactionDate: Time.now.strftime("%Y-%m-%d %H:%M"),
        panTermination: info[:panTermination],
        affiliation: self.merchant_afiliacion,
        merchant: self.merchant_numero
      }
      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, self.merchant_numero)

      if response[:error] == false
        respuesta = JSON.parse(response[:response])
        feenicia_log("guardar_venta", json.to_json, respuesta)
        #Si se guardó la venta, creamos el recibo.
        if respuesta["responseCode"] == "00"
          crear_recibo(order, transaction)
        else
          return {error: true, mensaje: "Ocurrió un error al guardar la venta"}
        end
      end

    end

    def crear_recibo(order, transaction)
      endpoint = "/receipt/receipt/CreateReceipt"
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv
      
      json = {
        OrderId: order,
        TransactionId: transaction,
        Total: 0.0,
        LegalEntityName: nil,
        MerchantStreetNumColony: nil, 
        MerchantCityStateZipCode: nil,
        AffiliationId: nil,
        LastDigitsCard: nil,
        Base64ImgSignature: nil,
        AuthNumber: nil,
        OperationId: nil,
        ControlNumber: nil,
        NameInCard: nil,
        DescriptionCard: nil,
        ReceiptDateTime: "0001-01-01T00:00:00",
        AID: nil,
        ARQC: nil,
        MensajeComercio: nil,
        ClientLogoBase64Data: nil,
        ClientLogoDataType: nil,
        SendUrlByMail: false,
        Propina: 0.0,
        strMerchantId: nil
      }

      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, self.merchant_numero)

      if response[:error] == false
        respuesta = JSON.parse(response[:response])
        feenicia_log("crear_recibo", json.to_json, respuesta)
        #Si se guardó la venta, creamos el recibo.
        if respuesta["responseCode"] == "00"
          id_recibo = respuesta["receiptId"]
          #Guardar el numero de recibo en info_transaccion
          self.info_transaccion[:receiptId] = respuesta["receiptId"]
          return {error: false, mensaje: "Factura pagada en línea exitosamente."}
          #enviar_recibo(id_recibo) se enviara un correo personalizado de parte de docDigitales
        else
          return {error: true, mensaje: "Ocurrió un error al crear el recibo"}
        end
      end

    end

    #Ya no se utiliza, se envia el recibo generado por docDigitales
    def enviar_recibo(id_recibo)
      endpoint = "/receipt/receipt/SendReceipt"
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv

      json = {
        receiptId: id_recibo,
        Email: [encriptar_sensible("manuel.robles@docdigitales.com")]
      }

      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, self.merchant_numero)

      if response[:error] == false
        respuesta = JSON.parse(response[:response])
        feenicia_log("enviar_recibo", json.to_json, respuesta)
        #Si se guardó la venta, creamos el recibo.
        if respuesta["responseCode"] == "00"
          return {error: false, mensaje: "Todo al 100 prro."}
        else
          return {error: true, mensaje: "Ocurrió un error al enviar el recibo"}
        end
      end
    end

    private

    def encriptar_sensible(dato)
      return Feenicia::encrypt(dato, self.request_key, self.request_iv)
    end
    
    #Registra peticion/respuesta log
    def feenicia_log(accion, request, response)
      log = FeeniciaLog.new
      log.empresa_id = self.empresa.id
      log.factura_id = self.factura.id
      log.accion = accion
      log.request = JSON.parse(request)
      log.response = response
      log.save
    end

  end

  class Merchant
    attr_accessor :request_key, :request_iv, :request_signature_key, :request_signature_iv, :response_key, :response_iv, :response_signature_key, :response_signature_iv, :rfc, :user_feenicia, :email, :empresa_id
    def initialize(merchant_feenicia, empresa_feenicia, empresa)
      self.request_key = ENV["feenicia_request_key"]
      self.request_iv = ENV["feenicia_request_iv"]
      self.request_signature_key = ENV["feenicia_request_signature_key"]
      self.request_signature_iv = ENV["feenicia_request_signature_iv"]
      self.response_key = ENV["feenicia_response_key"]
      self.response_iv = ENV["feenicia_response_iv"]
      self.response_signature_key = ENV["feenicia_response_signature_key"]
      self.response_signature_iv = ENV["feenicia_response_signature_iv"]
      self.rfc = empresa.rfc
      self.user_feenicia = merchant_feenicia.user_feenicia
      self.email = empresa_feenicia.email
      self.empresa_id = empresa.id
    end

    # Recibe un objeto de clase Contacto
    def registrar_info_contacto(contacto)
      endpoint = "/register/contact"
      json = contacto.to_hash(self.rfc)
      json_encrypted = encriptar_json(json)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, "FNZA_SSO")
      respuesta = JSON.parse(response[:response])
      host = ENV["feenicia_host"]
      feenicia_log("info_contacto", json.to_json, respuesta, host, endpoint,"FNZA_SSO", json_encrypted)
      return procesar_respuesta(response)
    end

    # Recibe un objeto de clase InfoFiscal
    def registrar_info_fiscal(info_fiscal)
      if Feenicia.persona_fisica?(self.rfc)
        endpoint = "/register/user/billing"
      else
        endpoint = "/register/company/billing"
      end
      json = info_fiscal.to_hash(self.rfc)
      json_encrypted = encriptar_json(json)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, "FNZA_SSO")
      respuesta = JSON.parse(response[:response])
      host = ENV["feenicia_host"]
      feenicia_log("info_fiscal", json.to_json, respuesta, host, endpoint, "FNZA_SSO", json_encrypted)
      return procesar_respuesta(response)
    end

    def registrar_info_domicilio(info_domicilio)
      if Feenicia.persona_fisica?(self.rfc)
        endpoint = "/register/user/address"
      else
        endpoint = "/register/company/address"
      end
      json = info_domicilio.to_hash(self.rfc)
      json_encrypted = encriptar_json(json)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, "FNZA_SSO")
      respuesta = JSON.parse(response[:response])
      host = ENV["feenicia_host"]
      feenicia_log("info_domicilio", json.to_json, respuesta, host, endpoint, "FNZA_SSO", json_encrypted)
      return procesar_respuesta(response)
    end

    def registrar_info_banco(info_banco)
      if Feenicia.persona_fisica?(self.rfc)
        endpoint = "/register/user/account"
      else
        endpoint = "/register/company/account"
      end
      json = info_banco.to_hash(self.rfc)
      json_encrypted = encriptar_json(json)
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, "FNZA_SSO")
      respuesta = JSON.parse(response[:response])
      host = ENV["feenicia_host"]
      feenicia_log("info_banco", json.to_json, respuesta, host, endpoint,"FNZA_SSO", json_encrypted)
      return procesar_respuesta(response)
    end

    def cargar_archivo(archivo, tipo)
      url = URI.parse(ENV["feenicia_host"])
      if Rails.env.staging? #Staging de prueba cambiar a env.production
        path = "/FNZA-Mobile/uploadFile"
      else
        path = "/mobile/uploadFile"
      end
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post::Multipart.new(path, params_file(archivo, tipo))

      mensaje = "Ocurrió un error al cargar documentación a Feenicia."
      begin
        response = http.request(request)
      rescue => exception
        ExceptionNotifier.notify_exception(exception, :data => {:fecha => Time.now.strftime("%FT%T.000"), :error => mensaje} )
        return { error: true, mensaje: mensaje }
      end

      code = response.code.to_i
      if code != 200
        ExceptionNotifier.notify_exception(exception, :data => {:fecha => Time.now.strftime("%FT%T.000"), :error => mensaje, :response => response.body} )
        return { error: true, mensaje: mensaje }
      end
      peticion = params_file(archivo, tipo).to_json
      respuesta = JSON.parse(response.body)
      host = ENV["feenicia_host"]
      feenicia_log("uploadFile #{tipo}",peticion,respuesta,host,path,nil,nil)
      if respuesta["responseCode"].present? && respuesta["responseCode"] == "00"
        link_archivo = respuesta["url"]
        return { error: false, mensaje: "Documento enviado a Feenicia correctamente.", link: link_archivo}
      else
        return { error: true, mensaje: mensaje }
      end

    end

    private
    def encriptar_json(json)
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv
      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      return json_encrypted
    end

    def procesar_respuesta(respuesta)
      if respuesta[:response].present?
        response = JSON.parse(respuesta[:response])
        response_code = response["responseCode"]
        if response_code == "00"
          return {error: false, mensaje: "Se actualizó la información del usuario correctamente."}
        else
          return {error: true, mensaje: "Ocurrió un error al registrar la información del usuario."}
        end
      else
        return {error: true, mensaje: "Ocurrió un error de comunicación con Feenicia."}
      end
    end

    #Registra peticion/respuesta log
    def feenicia_log(accion, request, response, host, endpoint, x_requested, json_encriptado)
      log = FeeniciaLog.new
      log.empresa_id = self.empresa_id
      log.factura_id = nil
      log.accion = accion
      log.request = JSON.parse(request)
      log.response = response
      log.host = host
      log.endpoint = endpoint
      log.x_requested = x_requested
      log.json_encriptado = json_encriptado
      log.save
    end

    def params_file(archivo, tipo_documento)
      params = {
        "userId" => self.user_feenicia,
        "email" => self.email,
        "fileType" => tipo_documento,
        "foto" =>  UploadIO.new(archivo.tempfile, archivo.content_type, archivo.original_filename )
      }
      params
    end

  end

  class Cuenta
    attr_accessor :request_key, :request_iv, :request_signature_key, :request_signature_iv,:response_key, :response_iv, :response_signature_key, :response_signature_iv, :usuario, :email
    protected :request_key, :request_iv, :request_signature_key, :request_signature_iv,:response_key, :response_iv, :response_signature_key, :response_signature_iv
    def initialize(usuario, email)
      self.usuario = usuario
      self.email = email
      self.request_key = ENV["feenicia_request_key"]
      self.request_iv = ENV["feenicia_request_iv"]
      self.request_signature_key = ENV["feenicia_request_signature_key"]
      self.request_signature_iv = ENV["feenicia_request_signature_iv"]
      self.response_key = ENV["feenicia_response_key"]
      self.response_iv = ENV["feenicia_response_iv"]
      self.response_signature_key = ENV["feenicia_response_signature_key"]
      self.response_signature_iv = ENV["feenicia_response_signature_iv"]
    end

    # Registra la empresa en Feenicia
    def registrar(password)
      if Rails.env.staging? #Staging de prueba cambiar a env.production quitar elsif
        endpoint = "/FNZA-Mobile/registerwhite" #Produccion
      elsif Rails.env.development?
        endpoint = "/FNZA-Mobile/registerwhite" #Produccion
      else
        endpoint = "/mobile/registerwhite" #Pruebas
      end
      key = self.request_key
      iv = self.request_iv
      sign_key = self.request_signature_key
      sign_iv = self.request_signature_iv

      json = {
        userId: usuario,
        email: email,
        password: Feenicia::encrypt(password, key, iv),
        appType: "FNZA_SITE",
        aplic: "docDigi"
      }

      json_encrypted = Feenicia::encrypt(json, sign_key, sign_iv, true)
      
      response = Feenicia::send_request(endpoint, json.to_json, json_encrypted, "FNZA_SSO")
      #Registrar el log
      respuesta = JSON.parse(response[:response])
      host = ENV["feenicia_host"]
      feenicia_log("registrar_usuario/#{usuario}", json.to_json, respuesta, host, endpoint, "FNZA_SSO", json_encrypted)
      #Procesar Respuesta
      respuesta_procesada = procesar_respuesta(response)
      return respuesta_procesada
    end

    private

    def procesar_respuesta(respuesta)
      res_key = self.response_key
      res_iv = self.response_iv
      if respuesta[:response].present?
        response = JSON.parse(respuesta[:response])
        response_code = response["responseCode"]
        if response_code == "00"
          keys = response["keys"]
          merchant = {
            user_feenicia: self.usuario,
            merchant_feenicia: response["merchant"],
            request_key: Feenicia::decrypt(keys["requestKey"], res_key, res_iv),
            request_iv: Feenicia::decrypt(keys["requestIv"], res_key, res_iv),
            request_signature_key: Feenicia::decrypt(keys["requestSignatureKey"], res_key, res_iv),
            request_signature_iv: Feenicia::decrypt(keys["requestSignatureIv"], res_key, res_iv),
            response_key: Feenicia::decrypt(keys["responseKey"], res_key, res_iv),
            response_iv: Feenicia::decrypt(keys["responseIv"], res_key, res_iv),
            response_signature_key: Feenicia::decrypt(keys["responseSignatureKey"], res_key, res_iv),
            response_signature_iv: Feenicia::decrypt(keys["responseSignatureIv"], res_key, res_iv)
          }
          return {error: false, merchant: merchant}
        else
          mensaje = mensaje_error(response_code)
          return {error: true, mensaje: mensaje}
        end
      else
        return {error: true, mensaje: "Ocurrió un error de comunicación con Feenicia."}
      end
    end

    #Registra peticion/respuesta log
    def feenicia_log(accion, request, response, host, endpoint, x_requested, json_encriptado)
      log = FeeniciaLog.new
      log.empresa_id = nil
      log.factura_id = nil
      log.accion = accion
      log.request = JSON.parse(request)
      log.response = response
      log.host = host
      log.endpoint = endpoint
      log.x_requested = x_requested
      log.json_encriptado = json_encriptado
      log.save
    end

    def mensaje_error(code)
      case code
        when "ZA001"
          "El correo electrónico ya existe Feenicia."
        when "ZA002"
          "El usuario ya existe en Feenicia."
        when "ZA004"
          "El usuario no puede estar vacío."
        when "ZA005"
          "La contraseña no es válida."
        when "ZA006"
          "El correo electrónico no es válido."
        when "ZA007"
          "El usuario no es válido."
        else
          "Ocurrió un error al registrar el usuario."
      end
    end

  end
  
  # Clase utilizada para mandar informacion de contacto a feenicia
  # formato de fecha de nacimiento => "birthdate":"Jul 09, 1994"
  class Contacto
    attr_accessor :nombre, :apellido_paterno, :apellido_materno, :telefono, :fecha_nacimiento, :email, :user_feenicia
    
    # Genera objeto Contacto con la informacion almacenada en EmpresaFeenicia
    def initialize(empresa_feenicia, merchant_feenicia, empresa)
      self.nombre           = empresa_feenicia.nombre
      self.apellido_paterno = empresa_feenicia.apellido_paterno
      self.apellido_materno = empresa_feenicia.apellido_materno
      self.telefono         = empresa_feenicia.telefono
      self.email            = empresa_feenicia.email
      self.fecha_nacimiento = empresa_feenicia.fecha_nacimiento
      self.user_feenicia    = merchant_feenicia.user_feenicia
    end

    def to_hash(rfc)
      tax = Feenicia.persona_fisica?(rfc) ? Feenicia::Impuesto::FISICA : Feenicia::Impuesto::MORAL

      return {
        name: nombre,
        lastName: apellido_paterno,
        secondSurName: apellido_materno,
        phone: telefono,
        tax: tax,
        birthdate: fecha_nacimiento,
        firstName: nombre,
        userId: user_feenicia,
        email: email,
        aplic: "docDigi"
      }
    end
  end

  # Clase utilizada para mandar Informacion Fiscal a feenicia
  # Si la empresa es Persona Fisica se le agregan los atributos shortName y legalEntityName
  # El giro proviene de un catalogo proporcionado por ellos
  class InfoFiscal
    attr_accessor :shortName, :legalEntityName, :giro, :telefono, :nombre_comercio, :email, :user_feenicia
    # Genera objeto InfoFiscal con la informacion almacenada en Empresa y EmpresaFeenicia
    def initialize(empresa_feenicia, merchant_feenicia, empresa)
        self.shortName        = empresa_feenicia.nombre_comercial
        self.legalEntityName  = empresa_feenicia.razon_social
        self.giro             = empresa_feenicia.giro
        self.telefono         = empresa_feenicia.telefono
        self.nombre_comercio  = empresa_feenicia.nombre_comercio
        self.email            = empresa_feenicia.email
        self.user_feenicia    = merchant_feenicia.user_feenicia
    end

    def to_hash(rfc)
      hash = {
        commerce_name: nombre_comercio,
        category: giro,
        phone: telefono,
        tin: rfc,
        email: email,
        userId: user_feenicia,
        aplic: "docDigi"
      }
      if !Feenicia.persona_fisica?(rfc)
        hash[:shortName] = shortName
        hash[:legalEntityName] = legalEntityName
      end

      return hash
    end
  end

  # Clase utilizada para mandar información direccion fiscal
  class Domicilio
    attr_accessor :estado, :municipio, :ciudad, :codigo_postal, :calle, :no_ext, :no_int, :email, :user_feenicia
    
    # Genera objeto domicilio con la informacion almacenada en Empresa
    def initialize(empresa_feenicia, merchant_feenicia, empresa)
      self.estado        = empresa_feenicia.estado
      self.municipio     = empresa_feenicia.municipio
      self.ciudad        = empresa_feenicia.ciudad
      self.codigo_postal = empresa_feenicia.codigo_postal
      self.calle         = empresa_feenicia.calle
      self.no_ext        = empresa_feenicia.no_exterior
      self.no_int        = empresa_feenicia.no_interior
      self.email         = empresa_feenicia.email
      self.user_feenicia = merchant_feenicia.user_feenicia
    end

    def to_hash(rfc)
      return {
        externalNumber: no_ext,
        internalNumber: no_int,
        street: calle,
        zipCode: codigo_postal,
        town: ciudad,
        city: ciudad,
        municipality: municipio,
        state: estado,
        country: "MEX",
        userId: user_feenicia,
        email: email,
        aplic: "docDigi"
      }
    end
  end

  # Clase utilizada para mandar información bancaria
  # clabe debe ser de 18 caracteres y el numero_cuenta de 8-10 caracteres
  class Banco
    attr_accessor :clabe, :numero_cuenta, :banco, :email, :user_feenicia

    # Genera objeto Banco con la informacion almacenada en EmpresaFeenicia
    def initialize(empresa_feenicia, merchant_feenicia, empresa)
      if empresa_feenicia.present?
        self.clabe         = empresa_feenicia.clabe
        self.numero_cuenta = empresa_feenicia.numero_cuenta
        self.banco         = empresa_feenicia.banco
        self.email         = empresa_feenicia.email
        self.user_feenicia = merchant_feenicia.user_feenicia
      end
      
    end

    def to_hash(rfc)
      return {
        clabe: clabe,
        account: numero_cuenta,
        bank: banco,
        userId: user_feenicia,
        email: email,
        aplic: "docDigi"
      }
    end
  end

  private
  # Si el RFC tiene 13 caracteres es de persona Física
  def self.persona_fisica?(rfc)
    return rfc.length == 13
  end

  def self.send_request(path, json, json_encrypted, x_requested)
    url = URI.parse(ENV["feenicia_host"])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(path)
    request["content-type"] = 'application/json'
    request["accept"] = 'application/json'
    request["x-requested-with"] = "#{x_requested}_" + json_encrypted
    
    begin
      request.body = json
      response = http.request(request)
    rescue => exception
      ExceptionNotifier.notify_exception(exception, :data => {:fecha => Time.now.strftime("%FT%T.000"), :json => json} )
      return { error: true }
    end

    code = response.code.to_i
    if code != 200
      ExceptionNotifier.notify_exception(exception, :data => {:fecha => Time.now.strftime("%FT%T.000"), :json => json, :response => response.body} )
      return { error: true }
    end

    return { error: false, response: response.body }
    
  end

  def self.encrypt(data, key, iv, signature = false)
    # Crear encriptador usando AES
    cipher = OpenSSL::Cipher.new("AES-128-CBC");
    cipher.encrypt;
    cipher.key = [key].pack("H*");
    cipher.iv = [iv].pack("H*");
    #Si es encriptado para generar el x-requested-with (signature) hacer el SHA256 del json.
    if signature == true
      json = data.to_json
      data = Digest::SHA256.hexdigest(json)
    end
    # Encripta hash y lo transforma a bytes (par de hexadecimales)
    resultado = cipher.update(data) << cipher.final;
    encrypted = resultado.each_byte.map { |b| b.to_s(16).rjust(2, '0') }.join
    return encrypted
  end

  def self.decrypt(encrypted_data, key, iv)
    # Crear desencriptado usando AES
    de_cipher = OpenSSL::Cipher.new("AES-128-CBC");
    de_cipher.decrypt;
    de_cipher.key = [key].pack("H*");
    de_cipher.iv = [iv].pack("H*");
    decrypted = de_cipher.update([encrypted_data].pack('H*')) << de_cipher.final;
    return decrypted
  end

end