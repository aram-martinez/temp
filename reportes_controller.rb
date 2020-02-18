class InterfazSistema::ReportesController < ApplicationController
  	before_action :login_required
  	before_action :is_accessible_interfaz_sistema
  	before_action :is_supervisor, :only => [:indicadores_index]
		before_action :set_catalogos_indicadores, :only => [:indicadores_index]
		before_action :set_catalogos_pago_linea, :only => [:pagos_linea_index]

	layout 'interfaz_sistema'
	def index
		@checkboxes = {"Ene" => "1", "Feb" => "2", "Mar" => "3", "Abr" => "4", "May" => "5", "Jun" => "6",
			"Jul" => "7", "Ago" => "8", "Sep" => "9", "Oct" => "10", "Nov" => "11", "Dic" => "12"	}
	end

	def reporte_listado_empresas
		#Recibir params
		filtros = params
		@empresas = Empresa.reporte_listado_empresas(filtros)
		respond_to do |format|
			format.xls
		end
	end

	def reporte_tracking_prueba_gratis
		@empresas_tracking = EmpresasTracking.all
		respond_to do |format|
			format.xls
		end
	end

	def reporte_medios_de_conversion
		@medios_de_conversion = EmpresasMediosDeConversion.all

		respond_to do |format|
			format.xls
		end
	end

	def reporte_listado_correos_empresas
		@empresas = Empresa.reporte_listado_correos_empresas
		respond_to do |format|
			format.xls
		end
	end

	def indicadores_index
	end

	def reportes_indicadores
		current_year = params[:year].to_i

		data_facturacion = IndicesFacturas.reporte_facturacion(current_year, 1)
		data_churn_rate = HistoricoPerdidaClientes.reporte_churn_rate(current_year)
		data_clientes_nuevos = FacturasRecibidas.reporte_clientes_nuevos_por_mes(current_year)

		response = {
			:data_facturacion => data_facturacion,
			:data_churn_rate => data_churn_rate,
			:data_clientes_nuevos => data_clientes_nuevos
		}
		
		render :json => response
	end

	def pagos_linea_index
	end

	def reportes_pagos_linea
		year = params[:busqueda]
		
		data_pagos_general = FeeniciaPago.reporte_pagos_por_mes(year)
		
		response = {
			:data_pagos_general => data_pagos_general
		}
		
		render json: response
	end

	def reporte_pagos_general
		year = params[:year]

		@pagos = FeeniciaPago.reporte_pagos_por_mes(year)	

		respond_to do |format|
			format.json { render json: @pagos}
		end
	end

	# Se manda llamar desde el menu de indicadores en la interfaz sistema.
	def reporte_facturacion
		current_year = params[:year].to_i
		@data = IndicesFacturas.reporte_facturacion(current_year, 1)

		respond_to do |format|
			format.json { render :json => @data }
			format.xls
		end
	end

	# Se manda llamar desde el menu de indicadores en la interfaz sistema.
	def reporte_churn_rate
		current_year = params[:year].to_i
		data = HistoricoPerdidaClientes.reporte_churn_rate(current_year)
		render :json => data
	end

	# Se manda llamar desde el menu de indicadores en la interfaz sistema.
	def reporte_clientes_nuevos
		current_year = params[:year].to_i
		data = FacturasRecibidas.reporte_clientes_nuevos_por_mes(current_year)
		render :json => data
	end

	def reporte_prospectos
		filtros = params
		if filtros[:year].present? && filtros[:meses].present?
			@prospectos = Empresa.reporte_prospectos(filtros)
			respond_to do |format|
				format.xlsx { response.headers['Content-Disposition'] = 'attachment; filename="reporte_prospectos.xlsx"' }
			end
		end
	end

	private
	def set_catalogos_indicadores
		@years = IndicesFacturas.select("DISTINCT(YEAR(fecha)) AS year").where("empresa_id = 1 AND YEAR(fecha) > 0").order("YEAR(fecha) DESC")
		@years_churn_rate = HistoricoPerdidaClientes.select("DISTINCT(YEAR(fecha)) AS year").order("YEAR(fecha) DESC")
		@years_clientes_nuevos = FacturasRecibidas.select("DISTINCT(YEAR(fecha)) AS year").order("YEAR(fecha) DESC")
	end

	def set_catalogos_pago_linea
		@years = FeeniciaPago.select("DISTINCT(YEAR(fecha_transaccion)) AS year").where("YEAR(fecha_transaccion) > 0").order("YEAR(fecha_transaccion) DESC")
	end
end
