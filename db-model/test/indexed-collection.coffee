assert = require('assert')
_ = require('lodash')
IC = require('../src/indexed-collection')

sample_data = [
	{id:'1000',name: 'one thousand', isNumber: true},
	{id:'1001',name: 'one thousand and one', isNumber: true},
]

describe "IndexedCollection", ()->
	describe "constructor", ()->
		it 'should create empty collection', ()->
			assert.deepEqual(new IC({}).asList(), [])

		it 'should create initialized collection', ()->
			assert.deepEqual(new IC({data: sample_data}).asList(), sample_data)

	describe "lookup", ()->
		it 'should lookup by id', ()->
			ic  = new IC({data: sample_data})
			for record in sample_data
				assert.deepEqual(ic.get(record.id), record)

		it 'should lookup by secondary index', ()->
			ic  = new IC({data: sample_data, columnIndexes:['name']})
			for record in sample_data
				assert.deepEqual(ic.getByIndex('name',record.name), record)

		it 'should iterate forEach in insertion order', ()->
			ic  = new IC({data: sample_data})
			idx = 0
			ic.forEach (value, key)->
				assert.deepEqual(value, sample_data[idx++])

	describe "set/update/delete", ()->
		it 'should insert a key', ()->
			ic  = new IC({data: sample_data})
			ic.set('1002', {id:'1002', name:'one thousand and two'})
			assert.equal(ic.length() , 3)

		it 'should update a key', ()->
			ic  = new IC({data: _.cloneDeep(sample_data)})
			ic.update('1001', {alias:'1000 + 1'})
			assert.deepEqual(ic.get('1001'), {alias:'1000 + 1', id:'1001', name:'one thousand and one',isNumber: true})

		it 'should update a key with custom update func', ()->
			ic  = new IC({data: _.cloneDeep(sample_data)})
			ic.update('1001', {double:'1001'})
			ic.update('1001', {double:'1001'}, (value, other)-> parseInt(value) +  parseInt(other))
			assert.deepEqual(ic.get('1001'), {double:2002, id:'1001', name:'one thousand and one', isNumber: true})

		it 'should delete a key', ()->
			ic  = new IC({data: sample_data})
			ic.delete('1001')
			assert.equal(ic.length() , 1)
			assert.deepEqual(ic.asList(), sample_data[0...1])

		it 'should update the secondary indexes', ()->
			ic  = new IC({data: _.cloneDeep(sample_data), columnIndexes:['name']})
			update  = {id:'1002', name:'one thousand and two updated'}
			ic.update('1002', update)
			assert.deepEqual(ic.getByIndex('name',update.name), update)

		it 'should allow multiple values in the secondary indexes', ()->
			ic  = new IC({data: _.cloneDeep(sample_data), columnIndexes:['isNumber']})
			assert.deepEqual(ic.getAllByIndex('isNumber',true), sample_data)
			ic.delete('1001')
			assert.deepEqual(ic.getAllByIndex('isNumber',true), [ sample_data[0] ])

	describe "filter", ()->
		it 'sould filter', ()->
			ic  = new IC({data: sample_data})
			assert.deepEqual(ic.filter([{field: "id", filters:{equals: "1000"}}]).asList(), [sample_data[0]])
			assert.deepEqual(ic.filter([{field: "name", filters:{has: "thousand"}}]).asList(), sample_data)

	describe "sort", ()->
		it 'should sort', ()->
			ic  = new IC({data: sample_data})
			ics = ic.sort(['id'])
			assert.deepEqual(ic.asList(), ics.asList())

	describe "groups", ()->
		it 'sould addToGroup/removeFromGroup', ()->
			ic  = new IC({data: sample_data})
			ic.addToGroup('test', '1000')
			assert.deepEqual(ic.getKeysInGroup('test'), ['1000'])
			ic.removeFromGroup('test', '1000')
			assert.deepEqual(ic.getKeysInGroup('test'), [])
		it 'sould autoGroup', ()->
			ic  = new IC({
				data: sample_data,
				autoGroups: {
					"by_id.*" : (value, key) -> value?.id
					"has_and" : (value, key) -> if value then value.name.indexOf(' and') >= 0 else false
					"by_name.*" : (value, key) -> value?.name
				}
			})
			#ic._dumpGroups()
			assert.deepEqual(ic.getKeysInGroup('by_id.1000'), ['1000'])
			assert.deepEqual(ic.getKeysInGroup('by_id.1001'), ['1001'])
			assert.deepEqual(ic.getKeysInGroup('has_and'), ['1001'])
			assert.deepEqual(ic.getGroups().sort(), ['by_id.1000', 'by_id.1001', 'has_and' ,'by_name.one thousand', 'by_name.one thousand and one'].sort())
