require 'sidekiq/web'
Rails.application.routes.draw do
  # Root Path a Iniciar Sesion
  root 'account/sessions#new'
  get 'sesion/status' => "sessions#verificar_status_sesion"
  get 'password_resets/new'

  # Cancelacion de facturas
  get "cancelar_factura/:id_f/:id_e"=> "admin/facturas#cancelar_factura_solicitud", :as =>"cancelar_factura"
  post "cancelar_factura/"          => "admin/facturas#cancelar_factura_archivos"
  post "cancelar_factura_respuesta/"=> "admin/facturas#cancelar_factura_respuesta"


  # Dashboard (Panel de Administracion)
  namespace :admin do
    resources :empresas_tracking
    get "actualizar_preferencias_correos"   =>  "empresas_preferencias#actualizar_preferencias_correos"
    resources :descargas_masivas
    resources :clientes_sucursales, only:[:create, :update, :destroy]
    resources :clientes do
      resources :clientes_contactos do
        collection do
          post ":contacto_id/actualizar" => "clientes_contactos#update_from_modal"
        end
      end
      collection do
        post "activar_restaurar"     => "clientes#activar_restaurar",   :as => "activar_restaurar"
        post "desactivar"            => "clientes#desactivar",          :as => "desactivar"
        post "eliminar"              => "clientes#eliminar",            :as => "eliminar"
        post "importar"              => "clientes#importar",            :as => "importar"
        get  "exportar"              => "clientes#exportar",            :as => "exportar"
        post "contactos"             => "clientes_contactos#create",    :as => "contactos-new"
        get  "contactos/:id/edit"    => "clientes_contactos#edit",      :as => "contactos-edit"
        post ":id/update_from_modal" => "clientes#update_from_modal",   :as => "update_from_modal"
        post "create_from_modal"     => "clientes#create_from_modal",   :as => "create_from_modal"
        get  "importar_clientes"     => "clientes#importar_index"   ,   :as => "importar_clientes"
        get "sucursal/:id"           => "clientes#sucursal"
        post "update_sucursal/:id"   => "clientes#update_sucursal"
        post "recordatorios" => "recordatorios_clientes#update"
        post "destruir_recordatorios" => "recordatorios_clientes#destroy"
      end
      collection do
        get   "busca_nombre_comercial_cliente" => "clientes#filter_by_client_comercial_name", :as => "busca_nombre_comercial_cliente"
        get   "descargar_plantilla"         => "clientes#descargar_plantilla",   :as => "descargar_plantilla"
        post  "busqueda/nombre"             => "clientes#busqueda_nombre"
        post  "busqueda/nombre_comercial"   => "clientes#busqueda_nombre_comercial"
        post  "busqueda/rfc"                => "clientes#busqueda_rfc"
        get   "filtros_cliente"             => "clientes#filtros_cliente"
        get   "clientes_paginados"          => "clientes#clientes_paginados"
        get   "bancos"                      => "clientes#bancos"
        get   "uso_cfdi_persona_fisica"     => "clientes#uso_cfdi_persona_fisica"
        get   "uso_cfdi_persona_moral"      => "clientes#uso_cfdi_persona_moral"
      end
      collection do
        get "validar_email_unico"    => "clientes_contactos#validar_email_unico", :as => "validar_email_unico"
        post "eliminar_contacto"            => "clientes_contactos#eliminar_contacto",  :as => "eliminar_contacto"
        get "validar_contacto_usuario_unico"    => "clientes_contactos#validar_contacto_usuario_unico", :as => "validar_contacto_usuario_unico"
      end
    end
    resources :facturas_recibidas do
      collection do
        post "eliminar"               => "facturas_recibidas#eliminar",          :as => "eliminar"
        post "restaurar"              => "facturas_recibidas#restaurar",         :as => "restaurar"
        post "descargar_pdf/:id/"     => "facturas_recibidas#descargar_pdf",     :as => "descargar_pdf"
        post "descargar_zip/:id/"     => "facturas_recibidas#descargar_zip",     :as => "descargar_zip"
        post "descarga_multiple/:id/" => "facturas_recibidas#descarga_multiple", :as => "descarga_multiple"
        post "enviar_gasto/:ids/"     => "facturas_recibidas#enviar_gasto",      :as => "enviar_gasto"
        post "asignar_gasto/"         => "facturas_recibidas#asignar_gasto",     :as => "asignar_gasto"
        post "set_estatus_leida/"     => "facturas_recibidas#set_estatus_leida", :as => "set_estatus_leida"
        post "busqueda/nombre"        => "facturas_recibidas#busqueda_proveedor_nombre"
        post "busqueda/rfc"           => "facturas_recibidas#busqueda_proveedor_rfc"
        post "procesar_por_cancelar"        => "facturas_recibidas#procesar_por_cancelar"
        get  "filtros_proveedor"      => "facturas_recibidas#filtros_proveedor"
        get  "validar_sat/:id"        => "facturas_recibidas#validar_sat"
        post "descargar_validacion_sat/:id/"            => "facturas_recibidas#descargar_validacion_sat", :as => "descargar_validacion_sat"
        post "descargar_validacion_forma_sintaxis/:id/" => "facturas_recibidas#descargar_validacion_forma_sintaxis", :as => "descargar_validacion_forma_sintaxis"
        post "categoria"              => "facturas_recibidas#categoria"
        get "abonos"                  => "facturas_recibidas#abonos"
      end
    end
    resources :facturas_recurrentes, only:[:index, :new, :create, :edit, :update, :show, :destroy] do
      resources :conceptos_recurrentes do
        collection do
          post "eliminar"   => "conceptos_recurrentes#eliminar"
          post "actualizar" => "conceptos_recurrentes#update"
        end
      end
      resources :conceptos_impuestos_recurrentes
      collection do
        post ":id/actualizar" => "facturas_recurrentes#actualizar"
        post "generar"        => "facturas_recurrentes#generar"
      end
      collection do
        post "eliminar"         => "facturas_recurrentes#eliminar",          :as => "eliminar"
        post "restaurar"        => "facturas_recurrentes#restaurar",         :as => "restaurar"
        post "activar"          => "facturas_recurrentes#activar",           :as => "activar"
        post "suspender"        => "facturas_recurrentes#suspender",         :as => "suspender"
        post "crear_factura"    => "facturas_recurrentes#crear_factura",     :as => "crear_factura"
        get "get_factura_notas" => "facturas_recurrentes#get_factura_notas", :as => "get_factura_notas"
        post ":id/actualizar"   => "facturas_recurrentes#actualizar"
        post "crear_preview"    => "facturas_recurrentes#crear_preview",     :as => "crear_preview"
        post "preview/:id"      => "facturas_recurrentes#preview",           :as => "preview"
        post "informacion_aduanera"        => "facturas_recurrentes#informacion_aduanera"
        get "crear_factura_servicio_auto"  => "facturas_recurrentes#factura_recurrente_servicio", :as => "factura_recurrente_servicio"
      end
    end
    resources :facturas, only:[:index, :new, :create, :edit, :update, :show] do
      resources :conceptos do
        collection do
          post "eliminar"   => "conceptos#eliminar"
          post "actualizar" => "conceptos#update"
        end
      end
      resources :conceptos_impuestos
      collection do
        post ":id/actualizar" => "facturas#actualizar"
        post "generar"        => "facturas#generar"
      end
      collection do
        post "enviar_factura"             => "facturas#enviar_factura",   :as => "enviar_factura"
        get "ver_factura/:id_f/:id_e"     => "facturas#ver_factura",      :as => "ver_factura"
        get "cancelar"                    => "facturas#cancelar_factura"

        post "validar"                    => "facturas#validaciones"
        get "buscarfolio"                 => "facturas#buscar_folio_por_serie"
        get "verificar_serie_folio"       => "facturas#verificar_serie_folio"
        get "buscartitulo"                => "facturas#buscar_titulo"
        get "informacionaduanera"         => "facturas#informacion_aduanera"
        get "nombre_impuesto"             => "facturas#nombre_impuesto"
        post "estatus_archivar"           => "facturas#estatus_archivar"
        get "get_factura_notas"           => "facturas#get_factura_notas",:as => "get_factura_notas"
        post "descargar_pdf/:id/"         => "facturas#descargar_pdf",    :as => "descargar_pdf"
        get "descargar_pdf/:id/"         => "facturas#descargar_pdf"
        post "descargar_pdf/:id_f/"       => "facturas#descargar_pdf",    :as => "descargar_pdf_ver_factura"
        post "descargar_zip/:id/"         => "facturas#descargar_zip",    :as => "descargar_zip"
        get "descargar_zip/:id/"         => "facturas#descargar_zip"
        post "descargar_zip/:id_f/"       => "facturas#descargar_zip",    :as => "descargar_zip_ver_factura"
        post "descargar_xml/:id/"         => "facturas#descargar_xml",    :as => "descargar_xml"
        post "descargar_xml_acuse/:id/"   => "facturas#factura_genera_xml_acuse", :as => "descargar_xml_acuse"
        post "descarga_multiple/:id/"     => "facturas#descarga_multiple",:as => "descarga_multiple"
        get "importar_facturas"           => "facturas#importar"   ,:as => "importar_facturas"
        post "importar"                   => "facturas#factura_importar"
        post "crear_preview"              => "facturas#crear_preview"    ,:as => "crear_preview"
        post "preview/:id"                => "facturas#preview"          ,:as => "preview"
        post "tab_eliminar"               => "facturas#enviar_tab_eliminar"
        post "restaurar"                  => "facturas#restaurar"
        post "eliminar"                   => "facturas#eliminar"
        get "generada/:id"                => "facturas#generada"
        post "ver_factura/:id/"           => "facturas#ver_pdf"          ,:as => "ver_pdf"
        get "abono/:id/"                  => "facturas#abono_pago"        ,:as => "abono"
        post "guardar_nota"               => "facturas#guardar_nota_abono"
        post "guardar_abono"              => "facturas#guardar_abono"
        post "hacer_default"              => "facturas#empresa_leyenda_default"
        post "correo_preset"              => "facturas#get_configuracion_correo_preset"
        get  "abonos"                     => "facturas#obtener_abonos"
        get "verificar_requeridos"        => "facturas#validar_campos_requeridos"
        get "validar_sat/:id/"            => "facturas#validar_sat"
        post "descargar_validacion_sat/:id/" => "facturas#descargar_validacion_sat", :as => "descargar_validacion_sat"
        post "descargar_validacion_forma_sintaxis/:id/" => "facturas#descargar_validacion_forma_sintaxis", :as => "descargar_validacion_forma_sintaxis"
        post "certificado_verificador"          => "facturas#factura_certificado_validacion_sat"
        get "abonos_multiples"                  => "facturas#facturas_abonos_multiples"
        post "catalogo_clave_producto_servicio" => "facturas#busqueda_catalogo_claves_productos_servicios"
        post "catalogo_clave_unidad"            => "facturas#busqueda_catalogo_clave_unidades"
        post "informacion_aduanera_aduana"      => "facturas#busqueda_informacion_aduanera_aduana"
        post "informacion_aduanera_patente"     => "facturas#busqueda_informacion_aduanera_patente"
        post "informacion_aduanera_ejercicio"   => "facturas#busqueda_informacion_aduanera_ejercicio"
        get "decimales_moneda"                  => "facturas#decimales_moneda"
        post "busqueda/recepciones_pagos/clientes"  => "facturas#busqueda_facturas_recepcion_pagos"
        get  "recepciones_relacionadas"             => "facturas#obtener_recepciones_pago_relacionados"
        get   "descargar_catalogo_claves_sat"       => "facturas#descargar_catalogo_claves_sat",   :as => "descargar_catalogo_claves_sat"
        get   "descargar_catalogo_unidades_sat"     => "facturas#descargar_catalogo_unidades_sat",   :as => "descargar_catalogo_unidades_sat"
        get "confirmacion" => "facturas#solicitar_confirmacion"
        post "list_facturas_cfdi_relacionado" => "facturas#list_facturas_cfdi_relacionado"
        post "verificar_cancelacion" => "facturas#verificar_cancelacion"
        post "envio_solicitud_cancelacion" => "facturas#envio_solicitud_cancelacion"
        post "reenviar_solicitud_cancelacion" => "facturas#reenviar_solicitud_cancelacion"
        get "obtener_correo_factura" => "facturas#obtener_correo_factura"
        get "cfdi_relacionados"               => "facturas#cfdi_relacionados"
      end
    end
    resources :cotizaciones, only:[:index, :new, :create, :edit, :update, :show]  do
      collection do
        post "eliminar"                         => "cotizaciones#eliminar",                   :as => "eliminar"
        get "copia_cotizacion"                  => "cotizaciones#copia_cotizacion",           :as => "copia_cotizacion"
        get "acepta_cotizacion/:id_e/:id_c"     => "cotizaciones#acepta_cotizacion",          :as => "acepta_cotizacion"
        post "cambiar_estatus_cotizacion"       => "cotizaciones#cambiar_estatus_cotizacion", :as => "cambiar_estatus_cotizacion"
        post "enviar_cotizacion"                => "cotizaciones#enviar_cotizacion",          :as => "enviar_cotizacion"
        post "cotizaciones_filter"              => "cotizaciones#cotizaciones_filter",        :as => "cotizaciones_filter"
        post "imprimir/:id"                     => "cotizaciones#imprimir",                   :as => "imprimir"
        get "imprimir_multiples/:cotizaciones" => "cotizaciones#imprimir_multiples",         :as => "imprimir_multiples"
        post "hacer_default"                    => "cotizaciones#empresa_leyenda_default"
        post "correo_preset"  => "cotizaciones#get_configuracion_correo_preset"
        post "imprimir_cot_vista/:id"           => "cotizaciones#imprimir_cot_vista",         :as => "imprimir_cot_vista"
      end
      resources :conceptos_cotizaciones do
        collection do
          post "eliminar"   => "conceptos_cotizaciones#eliminar"
          post "actualizar" => "conceptos_cotizaciones#update"
        end
      end
      resources :conceptos_cotizaciones_impuestos
      collection do
        post ":id/actualizar"       => "cotizaciones#actualizar"
        get  "busca_nombre_cliente" => "cotizaciones#filter_by_client_name", :as => "busca_nombre_cliente"
        get  "busca_rfc_cliente"    => "cotizaciones#filter_by_client_rfc",  :as => "busca_rfc_cliente"
      end
    end
    resource :empresa_feenicia, only: [:update] do
      collection do
        post "registrar_empresa_feenicia" => "empresa_feenicia#registrar_usuario"
        post "enviar_archivos_feenicia" => "empresa_feenicia#enviar_archivos"
        post "pagar_factura" => "empresa_feenicia#pagar_factura"
        post "enviar_recibo_pago" => "empresa_feenicia#enviar_recibo_pago"
        post "activar_pago_factura" => "empresa_feenicia#activar_pago_factura"
        post "informacion_feenicia" => "empresa_feenicia#informacion_feenicia"
      end
    end

    resources :empresas do
      collection do
        post "preferencias/facturas" => "empresas#campos_extras"
        post "importar/importar_imagen" => "empresas#importar_imagen"
        post "importar/imagenes"     => "empresas#imagenes"
        post "eliminar/imagenes"     => "empresas#eliminar_imagenes"
        post "actualizar/regimen"    => "empresas#actualizar_regimen_fiscal"
        get "validar_email_unico"    => "usuarios#validar_email_unico", :as => "validar_email_unico"
        get "validar_login_unico"    => "usuarios#validar_login_unico", :as => "validar_login_unico"
        get "verificar_empresa"      => "empresas#verificar_empresa"
        get "get_empresa_contacto"   => "empresas#get_empresa_contacto"
        get "verificar_paso_actual"  => "empresas#verificar_paso_actual"
        get "eliminar_ciec_error"   =>  "empresas#remove_ciec_error"
        put "registrar_datos_iniciales"        => "empresas#registrar_datos_iniciales"
        get "listados_get_registro"        => "empresas#listados_get_registro"
      end
      resources :usuarios do
        collection do
          post "eliminar"   => "usuarios#destroy"
          get "disponibles" => "usuarios#disponibles"
          post "cambiar_estatus" => "usuarios#cambiar_estatus"
        end
      end
      resources :empresas_leyendas,   :path => "leyendas"
      resources :empresas_sucursales, :path => "sucursales" do
        collection do
          post "eliminar" => "empresas_sucursales#eliminar"
        end
      end
      resources :empresas_sucursales_default, :path => "sucursales_default" do
        collection do
          post "establecer" => "empresas_sucursales_default#establecer"
        end
      end
      resources :empresas_usuarios, :path => "usuarios"
      resources :empresas_preferencias, :path => "preferencias" do
        collection do
          get "desactivar/reporte_semanal" => "empresas_preferencias#desactivar_reporte_semanal"
          get "activar/reporte_semanal" => "empresas_preferencias#activar_reporte_semanal"
        end
      end
      resources :impuestos do
        collection do
          post "eliminar" => "impuestos#destroy"
          get  "validar"  => "impuestos#validate_unique_tax"
        end
      end
      get "validar_impuesto_unico" => "impuestos#validate_unique_tax", :as => "validar_impuesto_unico"

      resources :empresas_correos, :path => "correos" do
        collection do
          get "get_configuracion_correo" => "empresas_correos#get_configuracion_correo", :as => "get_configuracion_correo"
          post "set_configuracion_correo" => "empresas_correos#set_configuracion_correo", :as => "set_configuracion_correo"
        end
      end

      resources :certificados do
        collection do
          post "importar/csd"     => "certificados#importar"
          post "importar/llaves"  => "llaves#importar"
          post "importar/ciec"    => "certificados#guardar_ciec"
          post "eliminar/llaves"  => "llaves#eliminar"
          post "eliminar/ciec"    => "certificados#eliminar_ciec"
          post "eliminar/certificados" => "certificados#eliminar_certificados"
        end
      end
      resources :empresas_productos, :path => "productos" do
        collection do
          post  "eliminar"            => "empresas_productos#destroy"
          post  "detalle"             => "empresas_productos#detalle_producto"
          get   "exportar/excel"      => "empresas_productos#exportar"
          get   "descargar_plantilla" => "empresas_productos#descargar_plantilla",   :as => "descargar_plantilla"
          post  "no_identificacion"   => "empresas_productos#busqueda_no_identificacion"
          post  "descripcion"         => "empresas_productos#busqueda_descripcion"
          post  "catalogo_productos"  => "empresas_productos#busqueda_catalogo_productos_sat"
          post  "catalogo_unidades"   => "empresas_productos#busqueda_catalogo_unidades_sat"
          post  "filtros_producto"    => "empresas_productos#filtros_producto"
          get   "listar"              => "empresas_productos#listar_productos"

          get   "importar/productos"  => "empresas_productos#importar_productos"
          post  "importar/excel"      => "empresas_productos#importar"
          get   "importar/estatus"    => "empresas_productos#importacion_estatus"
        end
        resources :empresas_productos_impuestos, :path => "impuestos" do
          collection do
            post "listar" => "empresas_productos_impuestos#listar_impuestos_producto"
          end
        end
      end
    end
    resources :nominas do
      collection do
        post "generar" => "nominas#generar_nomina", :as => "nominas-generar"
        get  "busca_nombre_empleado" => "nominas#filter_by_employee_name", :as => "busca_nombre_empleado"
        get  "busca_numero_empleado" => "nominas#filter_by_employee_number", :as => "busca_numero_empleado"
        get  "busca_rfc_empleado"    => "nominas#filter_by_employee_rfc",  :as => "busca_rfc_empleado"
        get  "filtrar"               => "nominas#filtrar"
        post "busqueda/nombre"       => "nominas#busqueda_nombre_empleado"
        post "busqueda/numero_empleado"  => "nominas#busqueda_numero_empleado"
        post "busqueda/rfc"          => "nominas#busqueda_rfc_empleado"
        post "cancelar"              => "nominas#cancelar",                   :as => "cancelar"
        post "enviar_nomina"         => "nominas#enviar_nomina",   :as => "enviar_nomina"
        post "descargar/:id/"    => "nominas#descargar",    :as => "descargar"
        post "descargar_zip/:id/"    => "nominas#descargar_zip",    :as => "descargar_zip"
        post "descarga_multiple/:id/"=> "nominas#descarga_multiple",:as => "descarga_multiple"
        get "validar_sat/:id/"                          => "nominas#validar_sat"
        post "descargar_validacion_sat/:id/"            => "nominas#descargar_validacion_sat", :as => "descargar_validacion_sat"
        post "descargar_validacion_forma_sintaxis/:id/" => "nominas#descargar_validacion_forma_sintaxis", :as => "descargar_validacion_forma_sintaxis"
        post "descargar_xml_acuse/:id/"   => "nominas#genera_xml_acuse", :as => "descargar_xml_acuse"
        get "ver_nomina/:id_e/:id_n" => "nominas#ver_nomina"
      end
    end
    resources :empleados do
      collection do
        post "eliminar"          => "empleados#eliminar",                 :as => "eliminar"
        post "tipos_detalles"    => "empleados#tipos_detalles"
        post "permisos"          => "usuarios_permisos_acciones#index"
        post "permisos/eliminar" => "usuarios_permisos_acciones#destroy"
        post "permisos/registrar"=> "usuarios_permisos_acciones#create"
        post "recurrencia/activar" => "empleados#activar_recurrencia"
        post "recurrencia/desactivar" => "empleados#desactivar_recurrencia"
        post "preview/:nombre"       => "empleados#preview",   :as => "preview"
        post "crear_preview"     => "empleados#crear_preview"
        patch "crear_preview"     => "empleados#crear_preview"
        post "prepara_preview"   => "empleados#prepara_preview",   :as => "prepara_preview"
        post "restaurar"         => "empleados#restaurar",                 :as => "restaurar"
        post "verificar_datos_empleado" => "empleados#verificar_datos_recurrencia"
        get  "validar/rfc"       => "empleados#validar_rfc"
      end
    end
    resources :staff_clientes, :path => 'asignaciones' do
      collection do
        post "eliminar"           => "staff_clientes#eliminar_clientes_empleado"
        post "registrar_clientes" => "staff_clientes#registrar_staff_a_clientes"
        post "registrar_staff"    => "staff_clientes#registrar_cliente_a_staff"
        post "clientes/empleados" => "staff_clientes#clientes_empleado"
        post "empleados/clientes" => "staff_clientes#empleados_clientes"
      end
    end
    resources :tipos_impuestos
    resources :precios do
      collection do
        post "pagos/paypal"                       => "precios#pagar_paypal"
        post "pagos/tarjeta"                      => "precios#pagar_tarjeta"
        post "pagos/tarjeta/existente"            => "precios#pagar_tarjeta_existente"
        post "editar/tarjeta"                     => "precios#editar_tarjeta"
        post "cancelar/suscripcion"               => "precios#cancelar_suscripcion"
        post "eliminar/tarjeta"                   => "precios#eliminar_tarjeta_suscripcion"
        post "agregar/tarjeta"                    => "precios#agregar_tarjeta"
        post "editar/quitar_adminsat_plan_actual" => "precios#quitar_adminsat_plan_actual"
        post "editar/actualizar_plan_actual"      => "precios#actualizar_plan_actual"
      end
    end
    resources :permisos_acciones, :path => 'permisos'
    resources :usuarios_permisos_acciones, :path => 'permisos_usuarios' do
      collection do
        post "listar" => "usuarios_permisos_acciones#listar"
      end
    end
    resources :series do
      collection do
        post "eliminar"           => "series#eliminar"
        post "establecer"         => "series_default#establecer"
        get "validar_serie_unica" => "series#validar_serie_unica", :as => "validar_serie_unica"
        get "proximo_folio"       => "series#proximo_folio"
      end
    end
    resources :gastos do
      collection do
        post "activar"                      => "gastos#activar",                      :as => "activar"
        post "archivar"                     => "gastos#archivar",                     :as => "archivar"
        post "eliminar"                     => "gastos#eliminar",                     :as => "eliminar"
        post "restaurar"                    => "gastos#restaurar",                    :as => "restaurar"
        post "detalle"                      => "gastos#gasto_por_id",                 :as => "detalle"
        post "gastos_filter"                => "gastos#gastos_filter",                :as => "gastos_filter"
        get "gasto_factura_recibida"        => "gastos#index_gasto_factura_recibida", :as => "gasto_factura_recibida"
        post "get_gasto_factura_recibida"   => "gastos#get_gasto_factura_recibida",   :as => "get_gasto_factura_recibida"
        post "crear_gasto_factura_recibida" => "gastos#crear_gasto_factura_recibida", :as => "crear_gasto_factura_recibida"
        post "actualizar_gasto/:id"         => "gastos#actualizar_gasto",             :as => "actualizar_gasto"
        post "asignar_factura/:gasto_id/"   => "gastos#asignar_factura",              :as => "asignar_factura"
        get "crear_gasto_servicio_auto"    => "gastos#crear_gasto_servicio",          :as => "crear_gasto_servicio"
      end
    end
    resources :gastos_categorias do
      collection do
        post "activar"                        => "gastos_categorias#activar",         :as => "activar"
        post "archivar"                       => "gastos_categorias#archivar",        :as => "archivar"
        post "eliminar"                       => "gastos_categorias#eliminar",        :as => "eliminar"
        post "restaurar"                      => "gastos_categorias#restaurar",       :as => "restaurar"
        get "listar/categorias/:query"        => "gastos_categorias#listar_categorias"
        post "gasto_categoria_por_id"         => "gastos_categorias#gasto_categoria_por_id"
        post "actualizar_gasto_categoria/:id" => "gastos_categorias#actualizar_gasto_categoria"
      end
    end
    resources :gastos_proveedores do
      collection do
        get "listar/proveedores/:query" => "gastos_proveedores#listar_proveedores"
      end
    end
    resources :notificaciones, only:[:index] do
      collection do
        post "notificacion_leida" => "notificaciones#notificacion_leida"
        post "eliminar" => "notificaciones#eliminar"
      end
    end
    resources :recepciones_pagos do
      collection do
        get "bancos" => "recepciones_pagos#informacion_bancaria"
        get "abonar/*id" => "recepciones_pagos#abonar_pago"
        get  "ver_recepcion/:id_f/:id_e"  => "recepciones_pagos#ver_recepcion",    :as => "ver_recepcion"
        post "descargar_pdf/:id/"         => "recepciones_pagos#descargar_pdf",    :as => "descargar_pdf"
        post "descargar_xml/:id/"         => "recepciones_pagos#descargar_xml",    :as => "descargar_xml"
        post "descargar_zip/:id/"         => "recepciones_pagos#descargar_zip",    :as => "descargar_zip"
        post "enviar_recepcion"           => "recepciones_pagos#enviar_recepcion"
        post "tab_eliminar"               => "recepciones_pagos#enviar_tab_eliminar"
        post "eliminar"                   => "recepciones_pagos#eliminar"
        post "restaurar"                  => "recepciones_pagos#restaurar"
        get  "facturas_relacionadas"      => "recepciones_pagos#obtener_facturas_relacionadas"
        get  "obtener_nota"               => "recepciones_pagos#obtener_nota"
        post "cancelacion"                => "recepciones_pagos#cancelacion"
        post "editar_nota"                => "recepciones_pagos#editar_nota"
        get "validar_sat/:id/"            => "recepciones_pagos#validar_sat"
        get "validar/variacion"           => "recepciones_pagos#porcentaje_variacion"
        get "obtener/tipo_cambio"         => "recepciones_pagos#tipo_cambio_actual"
        post "descargar_validacion_sat/:id/"            => "recepciones_pagos#descargar_validacion_sat", :as => "descargar_validacion_sat"
        post "descargar_validacion_forma_sintaxis/:id/" => "recepciones_pagos#descargar_validacion_forma_sintaxis", :as => "descargar_validacion_forma_sintaxis"
        post "descargar_xml_acuse/:id/"   => "recepciones_pagos#generar_xml_acuse", :as => "descargar_xml_acuse"
        get "generada/:id"                => "recepciones_pagos#generada"
        post "lista_recepciones_relacion" => "recepciones_pagos#obtener_recepciones_relacion"
        get "obtener_recepciones_relacion" => "recepciones_pagos#obtener_recepciones_pago_relacionados"
      end
    end
    resources :recepciones_pagos_recibidas do
      collection do
        post "descargar_pdf/:id/"  => "recepciones_pagos_recibidas#descargar_pdf",    :as => "descargar_pdf"
        post "descargar_xml/:id/"  => "recepciones_pagos_recibidas#descargar_xml",    :as => "descargar_xml"
        post "descargar_zip/:id/"  => "recepciones_pagos_recibidas#descargar_zip",    :as => "descargar_zip"
        post "busqueda/nombre"     => "recepciones_pagos_recibidas#busqueda_proveedor_nombre"
        post "busqueda/rfc"        => "recepciones_pagos_recibidas#busqueda_proveedor_rfc"
        get  "facturas_relacionadas" => "recepciones_pagos_recibidas#obtener_facturas_relacionadas"
        post "tab_eliminar"          => "recepciones_pagos_recibidas#enviar_tab_eliminar"
        post "eliminar"              => "recepciones_pagos_recibidas#eliminar"
        post "restaurar"             => "recepciones_pagos_recibidas#restaurar"
        get "validar_sat/:id/"       => "recepciones_pagos_recibidas#validar_sat"
        post "descargar_validacion_sat/:id/"            => "recepciones_pagos_recibidas#descargar_validacion_sat", :as => "descargar_validacion_sat"
        post "descargar_validacion_forma_sintaxis/:id/" => "recepciones_pagos_recibidas#descargar_validacion_forma_sintaxis", :as => "descargar_validacion_forma_sintaxis"
        post "certificado_verificador"          => "recepciones_pagos_recibidas#factura_certificado_validacion_sat"
      end
    end
  end
  # Configuracion
  namespace :configuracion do
    resources :mi_cuenta do
      collection do
        post "cambio/correo"   => "mi_cuenta#cambio_correo"
        get "agregar/empresa" => "mi_cuenta#agregar_empresa"
        post "guardar/empresa" => "mi_cuenta#guardar_empresa_nueva"
        get  "asignar/empresa" => "mi_cuenta#asignar_empresa"
        post "asignar/empresa/elegida" => "mi_cuenta#asignar_empresa_elegida"
        post "autenticar" => "mi_cuenta#autenticar_usuario"
        post "actualizar/perfil" => "mi_cuenta#actualizar_perfil"
        post "actualizar/password" => "mi_cuenta#actualizar_password"
        post "agregar/recepcion/facturas" => "mi_cuenta#recepcion_facturas"
        get "verificar/login" => "mi_cuenta#verificar_login"
        get "instrucciones_pago" => "mi_cuenta#imprimir_instrucciones_pago"
      end
    end
    resources :paquetes do
      collection do
        get  "cambiar"                 => "paquetes#cambiar_paquete"
        get  "recontratar"             => "paquetes#recontratar_paquete"
        post "detalle"                 => "paquetes#detalle_paquete"
        post "conekta/activar"         => "paquetes#activar_conekta"
        post "estimar_cobro"           => "paquetes#estimar_cobro_paquete"
        get "paypal/confirmacion/pago" => "paquetes#confirmacion"
      end
    end
    resources :recomendaciones do
      collection do
        get "/" => "recomendaciones#index"
        post "enviar" => "recomendaciones#enviar"
      end
    end
  end
  scope module: "account" do
    get "landing_pymes"                , to: redirect("/facturacion_en_linea")
    get "landing_mailing_pymes"        , to: redirect("/facturacion_en_linea_mailing")
    get "landing_contadores"           , to: redirect("/facturacion_multiempresas")
    get "facturacion_en_linea"          => "accounts#landing_abtesting"
    get "facturacion_en_linea_mailing" => "accounts#landing_mailing_pymes"
    get "facturacion_multiempresas"    => "accounts#landing_contadores"
    get "recomendacion"    => "accounts#landing_recomendados"
    post "enviar_correo"    => "accounts#enviar_correo_website"
  end

  # Cuentas
  # namespace :account, :requirements => { :rfc => /[\/]|[.]|[$]|[a-zA-z]|[0-9]/ } do
  namespace :account do
    get "login"                      => "sessions#new",                        :as => "login"
    get "logout"                     => "sessions#destroy",                    :as => "logout"
    get "logged_out"                 => "sessions#logged_out"
    post "enviar/correo/sugerencias" => "accounts#enviar_correo_sugerencias"
    get "registro/sistema"           => "accounts#new_empresa_prospecto_simple", :as => "registro_simple"
    get "dashboard"                  => "dashboard#index",                     :as => "dashboard"
    post "navegar_primeros_pasos"    => "dashboard#navegar_primeros_pasos"
    post "respuesta_adminsat_gratuito"    => "dashboard#respuesta_adminsat_gratuito"
    get "aviso_correo_confirmacion/:id"  => "accounts#aviso_correo_confirmacion",  :as => "aviso_correo_confirmacion"
    get "confirmacion_registro/:rfc" => "accounts#confirmacion_registro",      :as => "confirmacion_registro"
    get "validar_email_unico"        => "accounts#validar_email_unico",        :as => "validar_email_unico"
    get "validar_rfc_unico"          => "accounts#validar_rfc_unico",          :as => "validar_rfc_unico"
    get "validar_razon_social_unico" => "accounts#validar_razon_social_unico", :as => "validar_razon_social_unico"
    post "entrar"                    => "sessions#entrar"
    post "verificar_rol"              => "sessions#verificar_rol"
    post "verificar_usuario_estatus"  => "sessions#verificar_usuario_estatus"
    post "usuario_empresa"         => "sessions#usuario_empresa"
    post "cambiar/empresa"         => "dashboard#cambiar_empresa"
    post "reenviar_correo_confirmacion" => "accounts#reenviar_correo_confirmacion"
    get "promociones/validar" => "accounts#verificar_promocion"
    get "datos_bancarios" => "dashboard#no_mostrar_datos_bancarios"
    get "abrir_app" => "accounts#abrir_app"
    resources :accounts
    resources :password_resets
    post "enviar_correo_reset_password" => "password_resets#enviar_correo_reset_password"

    resources :sessions do
      collection do
        get "verificar/status"  => "sessions#verificar_status_sesion"
      end
    end
  end
  # Interfaz Sistema
  namespace :interfaz_sistema, only:[:index] do
    resources :home
    resources :notificaciones, only:[:index, :new, :create, :edit, :update, :show, :destroy] do
      collection do
        get "descargar_excel/:id" => "notificaciones#descargar_excel", :as => "descargar_excel"
      end
    end
    resources :reportes do
      collection do
        get "reporte_listado_empresas"          => "reportes#reporte_listado_empresas"
        get "reporte_medios_de_conversion"      => "reportes#reporte_medios_de_conversion"
        get "reporte_listado_correos_empresas"  => "reportes#reporte_listado_correos_empresas"
        get "reporte_tracking_prueba_gratis"    => "reportes#reporte_tracking_prueba_gratis"
        get "reporte_prospectos"                => "reportes#reporte_prospectos"
        get "indicadores"                       => "reportes#indicadores_index"
        get "reporte_facturacion"               => "reportes#reporte_facturacion"
        get "reporte_churn_rate"                => "reportes#reporte_churn_rate"
        get "reporte_clientes_nuevos"           => "reportes#reporte_clientes_nuevos"
				get "reportes_indicadores"              => "reportes#reportes_indicadores"
				get "pagos_linea"												=> "reportes#pagos_linea_index"
				get "reportes_pagos_linea"							=> "reportes#reportes_pagos_linea"
				get "reporte_pagos_general"							=> "reportes#reporte_pagos_general"
      end
    end
    resources :adendas do
      collection do
        post "registrar" => "adendas#registrar"
        post "editar"    => "adendas#editar"
        post "eliminar"  => "adendas#eliminar"
        post "registrar/concepto" => "adendas#registrar_concepto"
        post "asignar/empresa"  => "adendas#asignar_empresa"
        post "desasignar/empresa" => "adendas#desasignar_empresa"
        post "listar/empresas/adenda" => "adendas#listar_empresas_adenda"
      end
    end
    resources :empresas do
      collection do
        post "actualizar/empresa" => "empresas#actualizar_empresa"
        post "detalle" => "empresas#detalle"
        post "eliminar" => "empresas#eliminar"
        post "eliminar/conekta" => "empresas#eliminar_empresa_conekta"
        post "eliminar/creditos"=> "empresas#eliminar_creditos"
        post "agregar/creditos" => "empresas#agregar_creditos"
        post "actualizar/folio" => "empresas#actualizar_folio"
        post "activar"  => "empresas#activar"
        post "desactivar" => "empresas#desactivar"
        post "aplicar_pago"   => "empresas#aplicar_pago"
        post "asignar/empresa" => "empresas#asignar_empresa"
        post "busqueda/nombre" => "empresas#busqueda_nombre"
        post "busqueda/rfc"    => "empresas#busqueda_rfc"
        post "busqueda/id"    => "empresas#busqueda_id"
        post "busqueda/correo" => "empresas#busqueda_correo"
        post "busqueda/fechas" => "empresas#busqueda_fechas"
        post "busqueda/folio/serie" => "empresas#busqueda_folio_por_serie"
        post "busqueda/folio/disponible" => "empresas#busqueda_folio_disponible"
        post "pago_detalle" => "empresas#pago_detalle"
      end
      resources :certificados do
        collection do
          post "importar/csd"    => "certificados#importar"
          post "importar/llaves" => "llaves#importar"
          post "eliminar" => "certificados#eliminar_certificados"
        end
      end
    end
    resources :empresas_prospectos do
      collection do
        post "generar_accesos" => "empresas_prospectos#generar_accesos"
        post "eliminar" => "empresas_prospectos#eliminar"
        post "detalle" => "empresas_prospectos#detalle"
        post "busqueda/nombre" => "empresas_prospectos#busqueda_nombre"
        post "busqueda/rfc" => "empresas_prospectos#busqueda_rfc"
        post "busqueda/correo" => "empresas_prospectos#busqueda_correo"
      end
    end
    resources :clientes do
      collection do
        post "cambiar_correo" => "clientes#cambiar_correo"
        post "busqueda/nombre"=> "clientes#busqueda_nombre"
        post "busqueda/rfc"   => "clientes#busqueda_rfc"
      end
    end
    resources :usuarios do
      collection do
        post "registrar"  => "usuarios#registrar"
        post "editar"     => "usuarios#editar"
        post "eliminar"   => "usuarios#eliminar"
        post "enviar_correo"   => "usuarios#enviar_correo"
        post "cambiar_estatus" => "usuarios#cambiar_estatus"
      end
    end
    resources :paquetes do
        collection do
        get "detalle/:id" => "paquetes#detalle_paquete"
        end
    end
  end
  # Interfaz Cliente
  namespace :interfaz_cliente do
    resources :facturas do
    end
    resources :home
    resources :cotizaciones
    resources :configuraciones do
      collection do
        get "edit_contacto/:id" => "configuraciones#edit_contacto"
        post "actualizar/password" => "configuraciones#actualizar_password"
      end
    end
  end
  # Movil
  namespace :movil do
    resources :clientes
    resources :facturas
    resources :cotizaciones

    post "login"                               => "movil#login"

    get "getFactura/:factura_id"              => "facturas#get_factura"
    get "getAllFacturas/:empresa_id/"         => "facturas#get_all_facturas"
    get "getNotaOpcionalFactura/:id"          => "facturas#get_nota_opcional"
    get "getResumenFactura/:factura_id/"      => "facturas#get_resumen_factura"
    post "enviarFactura"                      => "facturas#enviar_factura"
    get "getAbono/:factura_id"                => "facturas#get_abono"
    post "saveAbono"                          => "facturas#save_abono"

    get "getCliente/:cliente_id/"             => "clientes#get_cliente"
    get "getAllClientes/:empresa_id/"         => "clientes#get_all_clientes"
    get "getAllClienteComboBox/:empresa_id/"  => "clientes#get_all_clientes_combobox"
    get "getPerfilCliente/:cliente_id/"       => "clientes#get_perfil_cliente"
    get "eliminarcliente/:cliente_id/"        => "clientes#delete"
    get "getUsoCFDIs"                         => "clientes#get_uso_cfdis"

    get "getNotaOpcionalCotizacion/:id"       => "cotizaciones#get_nota_opcional"
    get "getAllCotizaciones/:empresa_id/"     => "cotizaciones#get_all_cotizaciones"
    get "getCotizacion/:cotizacion_id"        => "cotizaciones#get_cotizacion"

    get "getGasto/:gasto_id/"                 => "gastos#get_gasto"
    get "getAllGastos/:empresa_id/"           => "gastos#get_all_gastos"
    post "saveGasto"                          => "gastos#save_gasto"

    get "getEmpresaLeyenda/:empresa_id"       => "configuracion#empresa_leyenda"
    get "informacion_aduanera/:empresa_id/"   => "configuracion#informacion_aduanera"

    get "getImpuestos/:empresa_id/"           => "configuracion#get_impuestos"
    post "saveImpuestos"                      => "configuracion#save_impuestos"
    post "deleteImpuesto/:impuesto_id"         => "configuracion#delete_impuesto"
    get "getSerie/:empresa_id/"               => "configuracion#get_serie"
    get "getTipoImpuestos/:empresa_id/"       => "configuracion#get_tipo_impuestos"
    get "getEmpresasUsuario/"                 => "configuracion#get_empresas_usuario"
    get "getAllProductos/:empresa_id/"        => "configuracion#get_all_productos"
    get "getImpuestosProductos/:empresa_id/"  => "configuracion#get_impuestos_producto"
    post "saveProducto"                       => "configuracion#save_producto"
    post "validateUsuario"                    => "configuracion#validate_usuario"
    post "updateEmpresa"                      => "configuracion#update_empresa"
    get "getMonedas"                          => "configuracion#get_monedas"
    get "getMetodosPagos"                     => "configuracion#get_metodos_pago"
    get "getCatalogoTasas"                    => "configuracion#get_catalogo_tasas"
  end

  # Listerns & Webhooks
  namespace :sistema do
    resources :catalogos do
      collection do
        get "impuestos/tasas_impuestos" => "catalogos#impuestos_tasas_impuestos"
        get "impuestos/tasas" => "catalogos#tasas"
        get "bancos/rfc" => "catalogos#bancos_rfc"
        post "codigo_postal/existe" => "catalogos#codigo_postal_existe"
      end
    end
    resources :correos do
      collection do
        post "reporte_semanal" => "correos#reporte_semanal"
      end
    end
    resources :webhooks do
      collection do
        post "conekta"  => "webhooks#conekta"
        post "paypal"   => "webhooks#paypal"
      end
    end
    resources :usuario_feature_anuncios, only: [:create]
    resources :reportes do
      collection do
        get "json_diaria" => "reportes#json_diaria"
        get  "facturas_mes"  => "reportes#reporte_facturas_mes"
        get  "gastos_mes"    => "reportes#reporte_gastos_mes"
        get  "gastos_categoria_mes" => "reportes#reporte_gastos_cateogiras_mes"
        post "gastos_mes_total" => "reportes#reporte_gastos_mes_total"
        get  "facturacion_diaria" => "reportes#reporte_facturacion_diaria"
        get  "exportar_facturacion_diaria" => "reportes#exportar_facturacion_diaria"
        get  "json_recepcion_pagos" => "reportes#json_recepcion_pagos"
        get  "recepcion_pagos" => "reportes#reporte_recepcion_pagos"
        get  "exportar_reporte_recepcion_pago" => "reportes#exportar_reporte_recepcion_pago"
        get  "facturas_recibidas" => "reportes#facturas_recibidas"
        get  "descarga_masiva" => "reportes#descarga_masiva"
        get  "nominas" => "reportes#reporte_nominas"
        get  "json_nominas" => "reportes#json_nominas"
        get  "exportar_nominas" => "reportes#exportar_nominas"
        post "exportar_descarga_masiva" => "reportes#exportar_descarga_masiva"
        get  "exportar_factuas_recibidas" => "reportes#exportar_factuas_recibidas"
        get  "ventas_por_cliente" => "reportes#reporte_ventas_por_cliente"
        get  "exportar_ventas_por_cliente" => "reportes#exportar_ventas_por_cliente"
        get  "ventas_por_staff" => "reportes#reporte_ventas_por_staff"
        get  "exportar_ventas_por_staff" => "reportes#exportar_ventas_por_staff"
        get  "devoluciones_por_cliente" => "reportes#reporte_descuentos_devoluciones_por_cliente", :as => "devoluciones_por_cliente"
        get  "exportar_devoluciones_por_cliente" => "reportes#exportar_descuentos_devoluciones_por_cliente"
        get  "cuentas_por_cobrar" => "reportes#reporte_cuentas_por_cobrar"
        get  "cuentas_por_cobrar_factura" => "reportes#reporte_cuentas_por_cobrar_factura"
        get  "exportar_cuentas_por_cobrar" => "reportes#exportar_cuentas_por_cobrar"
        get "gastos" => "reportes#gastos"
        get "exportar_gastos" => "reportes#exportar_gastos"
        get "ventas_por_producto" => "reportes#ventas_por_producto"
        post "ventas_por_producto_reporte" => "reportes#ventas_por_producto_reporte"
        get "exportar_ventas_por_producto" => "reportes#exportar_ventas_por_producto"
        post "generar_cuentas_por_cobrar_factura" => "reportes#generar_cuentas_por_cobrar_factura"
        get  "exportar_cuentas_por_cobrar_factura" => "reportes#exportar_cuentas_por_cobrar_factura"
      end
    end
    resources :graficas, only:[:index] do
      collection do
        get "get_all_graficas" => "graficas#get_all_graficas"
        get "get_grafica_facturacion" => "graficas#get_grafica_facturacion"
        post "bitacora_grafica" => "graficas#bitacora_grafica"
      end
    end
  end

  #sidekiq tareas programadas
  mount Sidekiq::Web, at: '/sidekiq'

  # Esta ruta es unicamnete para pruebas
  get "test_procesos/:test" => "test_procesos#inicio", :as => "test_procesos"

end
