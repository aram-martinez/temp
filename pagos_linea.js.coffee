@interfaz_sistema_pagos_linea_index = ->
	util = new Utilities()

	util.removeClass_on_menu_buttons($(".nav-item"), $("#menu_btn_pagos_linea"))

	interfaz_sistema_get_pagos_linea($('#years').val())
	
	$('#years').change ->
		interfaz_sistema_pagos_linea_general($('#years').val())
	
	return

interfaz_sistema_pagos_linea_general = (year) ->
	reportes_bloquear_tabla "#tbl-rpt-pagos-linea-general"
	$.ajax
		url: '/interfaz_sistema/reportes/reporte_pagos_general',
		type: "GET",
		data: year: year
		dataType: "json"
		success: (data) ->
			console.log data
			interfaz_sistema_pagos_linea_add_row_rpt_general(data)
		error: (data) ->
			msjAlertaDelay('danger', "Ocurrio un error al generar el reporte")

interfaz_sistema_get_pagos_linea = (busqueda) ->
	$.ajax
		url: '/interfaz_sistema/reportes/reportes_pagos_linea',
		type: "GET",
		data: busqueda: busqueda
		dataType: "json"
		success: (data) ->
			interfaz_sistema_pagos_linea_add_row_rpt_general(data.data_pagos_general)
		error: (data) ->
			msjAlertaDelay('danger', "Ocurrio un error al generar el reporte")

interfaz_sistema_pagos_linea_add_row_rpt_general = (data) ->
	source = $("#tmpl_rpt_pagos_linea_general_row").html()
	template = Handlebars.compile(source)
	$("#tbl-rpt-pagos-linea-general tbody").html("")
	$("#tbl-rpt-pagos-linea-general tbody").append(template(data))
	row = $('#tbl-rpt-pagos-linea-general tbody tr:last')

reportes_bloquear_tabla = (tabla)->
	$("#{tabla} tbody").block
		message: '<h2> Procesando</h2>'
		css:
			border: 'solid 1px lightgray'
			padding: '0 0 9px 0'
		overlayCSS:
			backgroundColor: '#fff'
