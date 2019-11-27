
FormMixin =
	getValues: ()->
		values = {}
		for key,input of @refs
			value = input.getValue().trim()
			if input.isCheckboxOrRadio()
				value = if input.getChecked() then 1 else 0

			continue if not value
			values[key] = value
		return values

module.exports = FormMixin