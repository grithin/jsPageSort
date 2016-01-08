# PageSort
A customisable tool for handling paging and sorting

## Use

```coffeescript
options =
	page:1
	pages:20
	sorts: '+name,-date'
	handlers:
		pull: PageSort.default_handlers.pull_static # default is non-static pull
	handlers_config:
		menu_paging_container:'#test'

# account for GET set params
set_options = Url.var('PageSort')
if set_options
	set_options = JSON.parse(set_options)
	options = _.extend(options, set_options)

pgsort = new PageSort(options)
```

## Dependencies
-	[Url, ](https://github.com/grithin/js_misc)
-	lodash
-	jquery

## Design Considerations
Designed for allowance of paging, sorting, and sub-sorting.  Provides standard paging menu, but sorting interface left up to impelenter.

In regard to data:
-	data can be present or not present on load
	-	data can be present within js
	-	data can be present as rendered html
	-	data may need to be fetched with ajax
-	the method for changing the page or sort can be ajax or static load

The ability to account for these cases is provided in the changeable `handlers` property