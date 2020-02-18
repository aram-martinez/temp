class FeeniciaPago < ActiveRecord::Base
  self.table_name = "feenicia_pagos"

  def self.informacion_pagos(empresa)
    hoy = Date.today
    info = FeeniciaPago.select("IFNULL(SUM(total),0) as total_pagos").where("empresa_id = #{empresa.id} AND DATE(created_at) = '#{hoy}' ").first
    feen_config = FeeniciaConfiguracion.find(1)

    total_pagado = info.total_pagos.to_f
    total_disponible = feen_config.limite_diario - total_pagado

    datos = {
      pagado: total_pagado,
      disponible: total_disponible
    }
    return datos
	end
	
	def self.reporte_pagos_por_mes(year)
		empresas_validadas = EmpresaFeenicia.where("estatus ='Validado' AND YEAR(fecha_validado) = #{year}")
		validados_por_mes = empresas_validadas.group_by { |e| e.fecha_validado.month}
		pagos = FeeniciaPago.where("aprobado = 1 AND YEAR(fecha_transaccion) = #{year}")
		pagos_por_mes = pagos.all.group_by { |p| p.fecha_transaccion.month}
			

		meses = {
			enero: {
				mes: 'Enero',
				mes_num: 1,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			febrero: {
				mes: 'Febrero',
				mes_num: 2,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			marzo: {
				mes: 'Marzo',
				mes_num: 3,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			abril: {
				mes: 'Abril',
				mes_num: 4,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			mayo: {
				mes: 'Mayo',
				mes_num: 5,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			junio: {
				mes: 'Junio',
				mes_num: 6,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			julio: {
				mes: 'Julio',
				mes_num: 7,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			agosto: {
				mes: 'Agosto',
				mes_num: 8,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			septiembre: {
				mes: 'Septiembre',
				mes_num: 9,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			octubre: {
				mes: 'Octubre',
				mes_num: 10,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			noviembre: {
				mes: 'Noviembre',
				mes_num: 11,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			},
			diciembre: {
				mes: 'Diciembre',
				mes_num: 12,
				total_pagado: 0,
				clientes_validos: 0,
				comision_feenicia: 0,
				iva_comision_f: 0,
				total_comision_f: 0,
				comision_docdigitales: 0
			}
		}

		# Arreglo con informacion de cada mes, se regresa como parte the la respuesta
		rows = Array.new(12)

		validados_por_mes.each do |e|
			case e[0]
			when 1
				meses[:enero][:clientes_validos] = e[1].count
			when 2
				meses[:febrero][:clientes_validos] = e[1].count
			when 3
				meses[:marzo][:clientes_validos] = e[1].count
			when 4
				meses[:abril][:clientes_validos] = e[1].count
			when 5
				meses[:mayo][:clientes_validos] = e[1].count
			when 6
				meses[:junio][:clientes_validos] = e[1].count
			when 7
				meses[:julio][:clientes_validos] = e[1].count
			when 8
				meses[:agosto][:clientes_validos] = e[1].count
			when 9
				meses[:septiembre][:clientes_validos] = e[1].count
			when 10
				meses[:octubre][:clientes_validos] = e[1].count
			when 11
				meses[:noviembre][:clientes_validos] = e[1].count
			when 12
				meses[:diciembre][:clientes_validos] = e[1].count
			end
		end

		pagos_por_mes.each do |p|
			total_visa_master = [0, 0, 0, 0]
			total_amex = [0, 0, 0, 0]
			total_por_tarjeta = [0, 0]
			temp_t = 0
			p[1].each do |tp|
				if tp.total <= 250000
					if ["Visa", "MasterCard"].include? tp.tipo_tarjeta
						total_visa_master[0] += tp.total.to_f
					else
						total_amex[0] += tp.total.to_f
					end
				elsif 250000 < tp.total <= 500000
					if ["Visa", "MasterCard"].include? tp.tipo_tarjeta
						total_visa_master[1] += tp.total.to_f
					else
						total_amex[1] += tp.total.to_f
					end
				elsif 500000 < tp.total <= 750000
					if ["Visa", "MasterCard"].include? tp.tipo_tarjeta
						total_visa_master[2] += tp.total.to_f
					else
						total_amex[2] += tp.total.to_f
					end
				else
					if ["Visa", "MasterCard"].include? tp.tipo_tarjeta
						total_visa_master[3] += tp.total.to_f
					else
						total_amex[3] += tp.total.to_f
					end
				end
				temp_t += tp.total.to_f
			end
			
			comision_feenicia = (temp_t * 0.026).round(1)
			iva_comision = (comision_feenicia * 0.16).round(2)
			total_comision_f = (comision_feenicia + iva_comision).round(2)
			comision_docdigitales = calcular_ganancia(total_visa_master, total_amex)

			case p[0]
			when 1
				meses[:enero][:total_pagado] = temp_t
				meses[:enero][:comision_feenicia] = comision_feenicia
				meses[:enero][:iva_comision_f] = iva_comision
				meses[:enero][:total_comision_f] = total_comision_f
				meses[:enero][:comision_docdigitales] = comision_docdigitales
			when 2
				meses[:febrero][:total_pagado] = temp_t
				meses[:febrero][:comision_feenicia] = comision_feenicia
				meses[:febrero][:iva_comision_f] = iva_comision
				meses[:febrero][:total_comision_f] = total_comision_f
				meses[:febrero][:comision_docdigitales] = comision_docdigitales
			when 3
				meses[:marzo][:total_pagado] = temp_t
				meses[:marzo][:comision_feenicia] = comision_feenicia
				meses[:marzo][:iva_comision_f] = iva_comision
				meses[:marzo][:total_comision_f] = total_comision_f
				meses[:marzo][:comision_docdigitales] = comision_docdigitales
			when 4
				meses[:abril][:total_pagado] = temp_t
				meses[:abril][:comision_feenicia] = comision_feenicia
				meses[:abril][:iva_comision_f] = iva_comision
				meses[:abril][:total_comision_f] = total_comision_f
				meses[:abril][:comision_docdigitales] = comision_docdigitales
			when 5
				meses[:mayo][:total_pagado] = temp_t
				meses[:mayo][:comision_feenicia] = comision_feenicia
				meses[:mayo][:iva_comision_f] = iva_comision
				meses[:mayo][:total_comision_f] = total_comision_f
				meses[:mayo][:comision_docdigitales] = comision_docdigitales
			when 6
				meses[:junio][:total_pagado] = temp_t
				meses[:junio][:comision_feenicia] = comision_feenicia
				meses[:junio][:iva_comision_f] = iva_comision
				meses[:junio][:total_comision_f] = total_comision_f
				meses[:junio][:comision_docdigitales] = comision_docdigitales
			when 7
				meses[:julio][:total_pagado] = temp_t
				meses[:julio][:comision_feenicia] = comision_feenicia
				meses[:julio][:iva_comision_f] = iva_comision
				meses[:julio][:total_comision_f] = total_comision_f
				meses[:julio][:comision_docdigitales] = comision_docdigitales
			when 8
				meses[:agosto][:total_pagado] = temp_t
				meses[:agosto][:comision_feenicia] = comision_feenicia
				meses[:agosto][:iva_comision_f] = iva_comision
				meses[:agosto][:total_comision_f] = total_comision_f
				meses[:agosto][:comision_docdigitales] = comision_docdigitales
			when 9
				meses[:septiembre][:total_pagado] = temp_t
				meses[:septiembre][:comision_feenicia] = comision_feenicia
				meses[:septiembre][:iva_comision_f] = iva_comision
				meses[:septiembre][:total_comision_f] = total_comision_f
				meses[:septiembre][:comision_docdigitales] = comision_docdigitales
			when 10
				meses[:octubre][:total_pagado] = temp_t
				meses[:octubre][:comision_feenicia] = comision_feenicia
				meses[:octubre][:iva_comision_f] = iva_comision
				meses[:octubre][:total_comision_f] = total_comision_f
				meses[:octubre][:comision_docdigitales] = comision_docdigitales
			when 11
				meses[:noviembre][:total_pagado] = temp_t
				meses[:noviembre][:comision_feenicia] = comision_feenicia
				meses[:noviembre][:iva_comision_f] = iva_comision
				meses[:noviembre][:total_comision_f] = total_comision_f
				meses[:noviembre][:comision_docdigitales] = comision_docdigitales
			when 12
				meses[:diciembre][:total_pagado] = temp_t
				meses[:diciembre][:comision_feenicia] = comision_feenicia
				meses[:diciembre][:iva_comision_f] = iva_comision
				meses[:diciembre][:total_comision_f] = total_comision_f
				meses[:diciembre][:comision_docdigitales] = comision_docdigitales
			end
		end

		meses.each do |mes|
			rows[mes[1][:mes_num] - 1] = mes[1]
		end

		datos = {
			rows: rows
		}
	end

	private
	
	def self.calcular_ganancia(visa_master, amex)
		ganancias = 0;
		ganancias += (visa_master[0] * 0.026)
		ganancias += (visa_master[1] * 0.0255)
		ganancias += (visa_master[2] * 0.025)
		ganancias += (visa_master[3] * 0.024)
		ganancias += (amex[0] * 0.028)
		ganancias += (amex[1] * 0.0278)
		ganancias += (amex[2] * 0.0275)
		ganancias += (amex[3] * 0.0270)
		
		return (ganancias).round(2)
	end
end
