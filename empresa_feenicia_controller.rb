# encoding: utf-8
class Admin::EmpresaFeeniciaController < ApplicationController
  include FacturasConcern

  before_action :login_required, :except => [:pagar_factura, :enviar_recibo_pago]

  def update
    empresa = current_company
    feenicia = EmpresaFeenicia.find_by(empresa_id: empresa.id)
    if feenicia.present?
      feenicia.update!(params_feenicia) if params[:empresa_feenicia].present?
    end
    
    if params[:submit] == "true"
      #Enviar informacion de contacto, fiscal, banco, etc a feenicia.
      envio = enviar_informacion(empresa, feenicia)
      #Registrar en feenicia proceso, que envio informacion personal.
      if envio[:error] == false
        feenicia_proc = FeeniciaProceso.find_by(empresa_id: empresa.id)
        feenicia_proc.informacion_personal = 1
        feenicia_proc.save
      end
      render json: envio
    else
      render plain: "", :status => 200
    end

  end

  def registrar_usuario
    empresa = current_company
    correo = params[:correo]
    usuario = params[:usuario]
    password = params[:password]
    cuenta = Feenicia::Cuenta.new(usuario, correo)
    respuesta = cuenta.registrar(password)

    #Si se creo la cuenta en feenicia, registramos la informacion del merchant(respuesta)
    if respuesta[:error] == false
      merchant = respuesta[:merchant]
      #Crear feenicia merchant
      fen_merchant = FeeniciaMerchant.new
      fen_merchant.empresa_id = empresa.id
      fen_merchant.merchant_feenicia = merchant[:merchant_feenicia]
      fen_merchant.user_feenicia = merchant[:user_feenicia]
      fen_merchant.request_key = merchant[:request_key]
      fen_merchant.request_iv = merchant[:request_iv]
      fen_merchant.request_signature_key = merchant[:request_signature_key]
      fen_merchant.request_signature_iv = merchant[:request_signature_iv]
      fen_merchant.response_key = merchant[:response_key]
      fen_merchant.response_iv = merchant[:response_iv]
      fen_merchant.response_signature_key = merchant[:response_signature_key]
      fen_merchant.response_signature_iv = merchant[:response_signature_iv]
      if fen_merchant.save!
        #Agregar correo a Empresa Feenicia
        feenicia = EmpresaFeenicia.find_or_create_by(empresa_id: empresa.id)
        feenicia.email = correo
        feenicia.rfc = empresa.rfc
        feenicia.save
        #Registrar en feenicia proceso, que se registro el usuario.
        feenicia_proc = FeeniciaProceso.find_or_create_by(empresa_id: empresa.id)
        feenicia_proc.registrado = 1
        feenicia_proc.save

        render json: {error: false} and return
      else
        render json: {error: true} and return
      end
    else
      render json: {error: true, mensaje: respuesta[:mensaje]} and return
    end

  end

  def enviar_archivos

    archivo = params[:archivo_feenicia]
    tipo_documento = params[:tipo_documento]
    empresa = current_company
    empresa_feenicia = EmpresaFeenicia.find_by(empresa_id: empresa.id)
    merchant_feenicia = FeeniciaMerchant.find_by(empresa_id: empresa.id)

    if merchant_feenicia.present? && empresa_feenicia.present?
      #Objeto Merchant
      merchant = Feenicia::Merchant.new(merchant_feenicia, empresa_feenicia, empresa)
      #Enviar Archivo
      respuesta = merchant.cargar_archivo(archivo, tipo_documento)
      link = ""
      if respuesta[:error] == false
        #Guardar info en FeeniciaProceso
        feenicia_proc = FeeniciaProceso.find_by(empresa_id: empresa.id)
        nombre_archivo = archivo.original_filename
        link = respuesta[:link]
        case tipo_documento
          when "CONT"
            feenicia_proc.doc_identificacion = nombre_archivo[0..44]
            feenicia_proc.link_identificacion = link
          when "RFC"
            feenicia_proc.doc_rfc = nombre_archivo[0..44]
            feenicia_proc.link_rfc = link
          when "ACTC"
            feenicia_proc.doc_acta = nombre_archivo[0..44]
            feenicia_proc.link_acta = link
          when "DOMC"
            feenicia_proc.doc_comprobante = nombre_archivo[0..44]
            feenicia_proc.link_comprobante = link
          when "CTAB"
            feenicia_proc.doc_cuenta = nombre_archivo[0..44]
            feenicia_proc.link_cuenta = link
        end
        feenicia_proc.save
      end
      render json: {error: respuesta[:error], mensaje: respuesta[:mensaje], link:link} and return
    end

  end

  def pagar_factura

    tarjeta = {
      tarjeta: decrypt_feenicia(params[:tarjeta]).delete(' '),
      nombre: decrypt_feenicia(params[:nombre]),
      cvv: decrypt_feenicia(params[:cvv]),
      vencimiento: decrypt_feenicia(params[:vencimiento])
    }

    factura = IndicesFacturas.find_by(factura_id: params[:factura_id])
    empresa = Empresa.find(params[:empresa_id])

    if factura.nil?
      render json: {error: true, mensaje: "No se encontró la factura, no es posible realizar el pago."} and return
    end

    if empresa.present?
      empresa_feenicia = EmpresaFeenicia.find_by(empresa_id: empresa.id)
      merchant_feenicia = FeeniciaMerchant.find_by(empresa_id: empresa.id)
    else
      render json: {error: true, mensaje: "No se encontró la empresa, no es posible realizar el pago."} and return 
    end

    if merchant_feenicia.present? && empresa_feenicia.present?
      #Crear objeto de venta manual, con todos sus atributos.
      venta = Feenicia::VentaManual.new(merchant_feenicia, empresa_feenicia, empresa, factura, tarjeta)
      #Generar la venta de la factura (cobro de factura)
			generar_venta = venta.generar_venta()
			#Registra venta ya sea aprobada o no
			registrar_pago_feenicia(venta.info_transaccion, factura)
      if generar_venta[:error] == false
        render json: {error: false, mensaje: "Se Pagó la factura Correctamente."} and return
      else
        render json: {error: true, mensaje: "Ocurrió un error al realizar el pago de la factura."} and return
      end
    else
      render json: {error: true, mensaje: "El emisor no puede recibir pagos."} and return
    end
  
  end

  def activar_pago_factura
    factura_id = params["factura_id"].to_i
    activo = params[:activo]
    indice_fact = IndicesFacturas.find_by_factura_id(factura_id)
    if indice_fact.present?
      if activo == "true"
        indice_fact.update!(pagar_linea: 1)
      else
        indice_fact.update!(pagar_linea: 0)
      end
      render json: {error: false, mensaje: "Información de pago en línea actualizada."} and return
    end
  end

  def enviar_recibo_pago
    correo = params[:correo]
    factura_id = params[:factura_id].to_i
    factura = Factura.find_historico(factura_id)
    feenicia_pago = FeeniciaPago.find_by(factura_id: factura_id)


    if factura.present? && feenicia_pago.present?
      # Informacion Correo Remitente.
      correo_empresa = Empresa.get_usuario_administrador(factura.empresa_id).login.downcase
      empresa = Empresa.find_by(id: factura.empresa_id)
      nombre_empresa =  empresa.nombre.present? ? empresa.nombre : empresa.razon_social

      #Folio de la factura para asunto del correo.
      folio = ""
      if factura.serie.blank?
        folio = factura.folio.to_s.rjust(6,'0')
      else
        folio = factura.serie + '-' + factura.folio.to_s.rjust(6,'0')
      end

      #Parametros del correo.
      asunto = "Comprobante de Pago en línea. Factura #{folio}"

      domicilio = {
        'calle'        => empresa.calle,
        'noExterior'   => empresa.no_exterior,
        'noInterior'   => empresa.no_interior,
        'colonia'      => empresa.colonia,
        'localidad'    => empresa.localidad,
        'municipio'    => empresa.municipio,
        'estado'       => empresa.estado,
        'pais'         => empresa.pais,
        'codigoPostal' => empresa.codigo_postal,
        'referencia'   => empresa.referencia
      }

      day = feenicia_pago.fecha_transaccion.strftime('%d')
      month = obtener_mes(feenicia_pago.fecha_transaccion.strftime('%m'))
      year = feenicia_pago.fecha_transaccion.strftime('%Y')
      hora = feenicia_pago.fecha_transaccion.strftime('%H:%M:%S')
      fecha_formato = "#{day} de #{month} de #{year} a las #{hora} hrs."

      params = {
        correo: correo,
        factura: factura,
        pago: feenicia_pago,
        correo_empresa: correo_empresa,
        nombre_empresa: nombre_empresa,
        domicilio_empresa: factura_direccion(domicilio),
        asunto: asunto,
        folio: folio,
        fecha: fecha_formato
      }
      #Enviar el correo
      enviar = FacturaMailer.recibo_pago_feenicia(params).deliver
      render json: {error: false, mensaje: "Comprobante de Pago en línea enviado correctamente."} and return
    else
      render json: {error: true, mensaje: "No existe información de pago para esa Factura."} and return
    end
  end

  def informacion_feenicia
    empresa_id = params[:empresa_id].to_i

    empresa = Empresa.find(empresa_id)
    empresa_feenicia = EmpresaFeenicia.find_by(empresa_id: empresa_id)

    if empresa.present? && empresa_feenicia.present?
      datos = {
        nombre: empresa_feenicia.nombre,
        app: empresa_feenicia.apellido_paterno,
        apm: empresa_feenicia.apellido_materno,
        tel: empresa_feenicia.telefono,
        fecha: empresa_feenicia.fecha_nacimiento,
        razon: (empresa_feenicia.razon_social.present? ? empresa_feenicia.razon_social : empresa.razon_social),
        nombre_comercial: (empresa_feenicia.nombre_comercial.present? ? empresa_feenicia.nombre_comercial : empresa.nombre),
        giro: empresa_feenicia.giro,
        rfc: (empresa_feenicia.rfc.present? ? empresa_feenicia.rfc : empresa.rfc),
        comercio: empresa_feenicia.nombre_comercio,
        calle: (empresa_feenicia.calle.present? ? empresa_feenicia.calle : empresa.calle),
        num_ext: (empresa_feenicia.no_exterior.present? ? empresa_feenicia.no_exterior : empresa.no_exterior),
        num_int: (empresa_feenicia.no_interior.present? ? empresa_feenicia.no_interior : empresa.no_interior),
        cp: (empresa_feenicia.codigo_postal.present? ? empresa_feenicia.codigo_postal : empresa.codigo_postal),
        colonia: (empresa_feenicia.colonia.present? ? empresa_feenicia.colonia : empresa.colonia),
        municipio: (empresa_feenicia.municipio.present? ? empresa_feenicia.municipio : empresa.municipio),
        ciudad: (empresa_feenicia.ciudad.present? ? empresa_feenicia.ciudad : empresa.localidad),
        estado: empresa_feenicia.estado,
        pais: "México",
        banco: empresa_feenicia.banco,
        cuenta: empresa_feenicia.numero_cuenta,
        clabe: empresa_feenicia.clabe
      }
      render json: {error: false, datos: datos} and return
    else
      render json: {error: true, datos: nil} and return
    end
  end

  private

  def registrar_pago_feenicia(info, factura)
    #Guardar pago feenicia 🤑
    pago_feenicia = FeeniciaPago.new
    pago_feenicia.empresa_id = info[:empresa_id]
    pago_feenicia.factura_id = info[:factura_id]
    pago_feenicia.total = factura.total
    pago_feenicia.num_recibo = info[:receiptId]
    pago_feenicia.num_afiliacion = info[:affiliation]
    pago_feenicia.num_transaccion = info[:transactionId]
    pago_feenicia.num_autorizacion = info[:authnum]
    pago_feenicia.num_control = info[:orderId]
    pago_feenicia.num_tarjeta = info[:last4Digits]
		pago_feenicia.fecha_transaccion = info[:transactionDate]
		pago_feenicia.aprobado = info[:aprobado]
		pago_feenicia.tipo_tarjeta = info[:tipo_tarjeta]
		pago_feenicia.save

		#Crear registro en bitacora factura 📙
		if pago_feenicia.aprobado == 1
    	factura_bitacora(info[:factura_id], "Factura pagada en línea", "Pagada")
		else
			factura_bitacora(info[:factura_id], "Factura no pagada. Pago no aprobado", "No Pagada")
		end
    #Crear notificacion
    factura = Factura.find_historico(info[:factura_id].to_i)
    empresa = Empresa.find(factura.empresa_id)
    cliente = Cliente.find(factura.cliente_id)
    
    folio = ""
    if factura.serie.blank?
      folio = factura.folio.to_s.rjust(6,'0')
    else
      folio = factura.serie + '-' + factura.folio.to_s.rjust(6,'0')
    end

    cliente_nombre = cliente.nombre.present? ? cliente.nombre : cliente.rfc
    path_factura = ENV['host_url']+"/admin/facturas/#{factura.id}"
    link = "<a href=\"#{path_factura}\">#{folio}</a>"
		
		if pago_feenicia.aprobado == 1
			descripcion_notificacion = "Hola, tu cliente <b>#{cliente_nombre}</b> te acaba de pagar la factura <b>#{link}</b>  por medio de la función de Pago en línea del sistema docDigitales."
			crear_notificacion("Factura #{folio} Pagada en línea.", descripcion_notificacion, 1, empresa.id, 4)
			
			#Marcar como pagada la factura (Indices, Factura)
			indice_fact = IndicesFacturas.find_by_factura_id(factura.id)
			indice_fact.update!(estatus: 4)
			factura.update!(estatus: 4)
		end
  end

  def decrypt_feenicia(dato)
    #Desencriptar el dato
    password = ENV["feenicia_decrypt_key"]
    feenicia_config = FeeniciaConfiguracion.find(1)
    priv_key =  feenicia_config.llave_privada
    key      = OpenSSL::PKey::RSA.new priv_key, password
    encrypted_massage = Base64.decode64 dato 
    result = key.private_decrypt encrypted_massage
    return result
  end

  def enviar_informacion(empresa, empresa_feenicia)
    merchant_feenicia = FeeniciaMerchant.find_by(empresa_id: empresa.id)
    if merchant_feenicia.present?
      #Objeto Merchant
      merchant = Feenicia::Merchant.new(merchant_feenicia, empresa_feenicia, empresa)
      #Informormacion del cliente
      info_contacto  = Feenicia::Contacto.new(empresa_feenicia, merchant_feenicia, empresa)
      info_fiscal  = Feenicia::InfoFiscal.new(empresa_feenicia, merchant_feenicia, empresa)
      info_domicilio = Feenicia::Domicilio.new(empresa_feenicia, merchant_feenicia, empresa)
      info_banco = Feenicia::Banco.new(empresa_feenicia, merchant_feenicia, empresa)
      #Respuestas de cada petición
      res_contacto  = merchant.registrar_info_contacto(info_contacto)
      res_fiscal    = merchant.registrar_info_fiscal(info_fiscal)
      res_domicilio = merchant.registrar_info_domicilio(info_domicilio)
      res_banco     = merchant.registrar_info_banco(info_banco)
      
      #Validar que no exista ningun error en las peticiones (para dejar avanzar al usuario)
      if res_contacto[:error] == true || res_fiscal[:error] == true || res_domicilio[:error] == true || res_banco[:error] == true
        return {error: true, mensaje: "Ocurrió un error al registrar su información en Feenicia, favor de intentar mas tarde."}
      else
        return {error: false}
      end
    end
  end

  def factura_direccion(domicilio_fiscal)
    direccion_empresa = domicilio_fiscal['calle']

    if not domicilio_fiscal['noExterior'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['noExterior'] : direccion_empresa+' '+ domicilio_fiscal['noExterior']
    end

    if not domicilio_fiscal['noInterior'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['noInterior'] : direccion_empresa+' '+ domicilio_fiscal['noInterior']
    end

    if not domicilio_fiscal['colonia'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['colonia'] : direccion_empresa+' '+ domicilio_fiscal['colonia']
    end

    if not domicilio_fiscal['codigoPostal'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['codigoPostal'] : direccion_empresa+', CP '+ domicilio_fiscal['codigoPostal']
    end

    if not domicilio_fiscal['municipio'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['municipio'] : direccion_empresa+', '+ domicilio_fiscal['municipio']
    end

    if not domicilio_fiscal['estado'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['estado'] : direccion_empresa+', '+ domicilio_fiscal['estado']
    end

    if not domicilio_fiscal['pais'].blank?
      direccion_empresa = direccion_empresa.blank? ? domicilio_fiscal['pais'] : direccion_empresa+', '+ domicilio_fiscal['pais']
    end

    direccion_empresa
  end

  def obtener_mes(mes)
    
    case mes
    when "01"
      "Enero"
    when "02"
      "Febrero"
    when "03"
      "Marzo"
    when "04"
      "Abril"
    when "05"
      "Mayo"
    when "06"
      "Junio"
    when "07"
      "Julio"
    when "08"
      "Agosto"
    when "09"
      "Septiembre"
    when "10"
      "Octubre"
    when "11"
      "Noviembre"
    when "12"
      "Diciembre"
    end
  end

  def params_feenicia
    params.require(:empresa_feenicia).permit(:nombre, :nombre_comercio, :apellido_paterno, :apellido_materno, :telefono, :fecha_nacimiento, :estado, :giro, :banco, :numero_cuenta, :clabe,:razon_social, :nombre_comercial, :calle, :no_exterior, :no_interior, :codigo_postal, :colonia, :municipio, :pais, :ciudad)
  end
end
