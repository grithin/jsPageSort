###
@param	options	{
	changed:<force an update once (will reset)>
	page:x,
	pages:x
	sorts:<either short form, combined with ",", or array or sort objects>,
	handlers_config: <optional>{
		data_url: <defaults to current.  Used for data pull>,
		menu_paging_context: <surrounding pages within menu>,
		menu_paging_container: <element within which to construct paging menu>
		}
	handlers:{
		pull:<fn>,
		data:<fn>,
		menu:<fn>}	}
###

_statics = ()-> # use with .bind()
	# parses a single short-form sort string into a sort object
	this.parse_sort = (short_form_sort)->
		if typeof(short_form_sort) != typeof('') #< param not a string, return it
			return short_form_sort
		will_return = {order:'-', field:'', defaulted_order:true}
		first_character = short_form_sort.substring(0,1)
		if first_character == '-' || first_character == '+'
			will_return.field = short_form_sort.substring(1)
			will_return.order = first_character
			will_return.defaulted_order = false
		else
			will_return.field = short_form_sort

		return will_return
	this.parse_sorts = (short_form_sorts)=>
		if typeof(short_form_sorts) == typeof('')# turn `,` separation into array
			short_form_sorts = short_form_sorts.split(',')
		if !Array.isArray(short_form_sorts)
			return short_form_sorts
		sorts = []
		for sort in short_form_sorts
			sorts.push(this.parse_sort(sort))
		return sorts

	this.format_to_short_sorts = (sorts)->
		short_format = []
		for sort in sorts
			short_format.push(sort.order + sort.field)
		return short_format.join(',')

	this.default_handlers = {
		pull:()->
			$.ajax(
				url:this.url,
				contentType:'application/json',
				data:JSON.stringify(this.get_request_meta),
				dataType:'json',
				method:'POST',
				success: (json)=>
					this.pages = json.meta.pages
					this.apply_changed(json.data)	)
		pull_static:()->
			window.location = Url.append('PageSort',JSON.stringify(this.get_request_meta()),{url:this.url})
		menu:()->
			if !this.pages || this.pages < 2
				return
			if !this.paging_menu
				if !this.handlers_config.menu_paging_container
					throw new Exception('No Paging Menu')
				else
					paging_menu_container = $(this.handlers_config.menu_paging_container)
					this.paging_menu =  $('<div class="paging_menu"></div>')
					paging_menu_container.append(this.paging_menu)

			paging_menu = this.paging_menu #< shortening reference

			# clear menu for update
			paging_menu.html('')

			#++ center the current page if possible {
			context = this.handlers_config.menu_paging_context # only  show context * 2 + 1 page buttons
			start = Math.max((this.page - context), 1)
			end = Math.min((this.page + context), this.pages)
			extraContext = context - (this.page - start)
			if extraContext
				end = Math.min(end + extraContext, this.pages)
			else
				extraContext = context - (end - this.page)
				if extraContext
					start = Math.max(start - extraContext, 1)
			#++ }

			#++ make the menu {
			if this.page != 1
				paging_menu.append('<div class="clk first">&lt;&lt;</div><div class="clk prev">&nbsp;&lt;&nbsp;</div>')
			for i in [start..end]
				special_class = if i == this.page then ' current' else ''
				paging_menu.append('<div class="clk pg' + special_class + '">' + i + '</div>')
			if this.page != this.pages
				paging_menu.append('<div class="clk next">&nbsp;&gt;&nbsp;</div><div class="clk last">&gt;&gt;</div>')
			paging_menu.append("<div class='direct'>"+
						"<input title='Total of " + this.pages + "' type='text' name='go_to_page' value='" + this.page + "'/>"+
						"<div class='clk go'>Go</div>"+
					"</div>")
			#++ }


			# set up click handling
			$('.clk:not(.disabled)',paging_menu).click(this.menu_paging_click_handler)

			# ensure "enter" on "go" field changes page, not some other form
			$('input[name="go_to_page"]', this.paging_menu).keypress((e)=>
				if e.which == 13
					e.preventDefault()
					$('.go',this.paging_menu).click()	)
		}

this.PageSort = (options)->
	_statics.bind(this)()

	# conditionally handle an update request
	this.command = (update)->
		changed = false
		if update.page && this.page != update.page
			this.page = update.page
			changed = true
		if update.sort && this.sort != update.sort
			this.sort = update.sort
			changed = true
		if changed
			this.handlers.pull() #< since "this" traverses up, don't need to use .call(this)
	# add or switch a sort
	this.append_sort = (new_sort)=>
		new_sort = this.parse_sort(new_sort)
		# if new_sort in sorts, switch order
		for sort in this.sorts
			if new_sort.field == sort.field
				sort.order = (sort.order == '+' && '-') || '+' # ternary toggle
				return
		this.sorts.push(new_sort)

	# apply or toggle a sort, replacing current sorts
	this.switch_sort = (new_sort)=>
		new_sort = this.parse_sort(new_sort)
		if new_sort.order_defaulted && this.sorts.length > 0 && this.sorts[0].field == new_sort.field #< handle toggle scenario
			new_sort.order = (this.sorts[0].order == '+' && '-') || '+' # ternary toggle
		this.sorts = [new_sort]

	# assuming this. menu attributes have been changed, take new row data and apply it
	this.apply_changed = (data)=>
		this.handlers.data(data)
		this.handlers.menu()

	this.get_request_meta = ()=>
		return {
			page: this.page
			sorts: this.format_to_short_sorts(this.sorts)
			per_page: this.per_page}

	this.menu_paging_click_handler = (e)=>
		target = $(e.target)
		if target.hasClass('pg')
			page = target.text()
		else if target.hasClass('next')
			page = this.page + 1
		else if target.hasClass('last')
			page = this.pages
		else if target.hasClass('first')
			page = 1
		else if target.hasClass('prev')
			page = this.page - 1
		else if target.hasClass('go')
			page = Math.abs($('input[name="go_to_page"]', this.paging_menu).val())
		this.command({page:page})


	this.default_handlers_config =
		menu_paging_context: 2 # number of page numbers to show on a side of the current within the menu
		menu_paging_container: '#pagination_menu_container'
		data_url:window.location

	#++ handle options, defaults {
	this.page = 1
	this.per_page = 0
	this.sorts = []
	_.extend(this, options || {}) #< apply options over defaults

	this.handlers = _.defaults(this.handlers || {}, this.default_handlers)
	this.handlers_config = _.defaults(this.handlers_config || {}, this.default_handlers_config)

	# since handlers rely on reference to `this`, bind them
	for name, handler of this.handlers
		this.handlers[name] = handler.bind(this)

	this.pages = parseInt(this.pages)
	this.page = parseInt(this.page)
	this.per_page = parseInt(this.per_page)

	if this.sorts
		this.sorts = this.parse_sorts(this.sorts)
	#++ }

	this.handlers.menu()

_statics.bind(PageSort)()