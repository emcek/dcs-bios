local ControlType = require("ControlType")
local MockDevice = require("MockDevice")
local Module = require("Module")

local lu = require("luaunit")

--- @class TestReadWriteRadio
--- @field module Module
TestReadWriteRadio = {}
local moduleName = "MyModule"
local moduleAddress = 0x4200

function TestReadWriteRadio:setUp()
	self.module = Module:new(moduleName, moduleAddress, {})
	Input_Processor_Device = MockDevice:new(0)
end

local id = "MY_READ_WRITE_RADIO_INPUT"
local device_id = 1
local scale_factor = 1000
local category = "Radio Frequencies"
local description = "This is a read-write radio"

function TestReadWriteRadio:testAddReadWriteRadio()
	local max_length = 7
	local decimal_places = 3
	local control = self.module:defineReadWriteRadio(id, device_id, max_length, decimal_places, scale_factor, description)

	lu.assertEquals(control, self.module.documentation[category][id])
	lu.assertEquals(control.control_type, ControlType.radio)
	lu.assertEquals(control.category, category)
	lu.assertEquals(control.description, description)
	lu.assertEquals(control.identifier, id)
	lu.assertIsNil(control.momentary_positions)
	lu.assertIsNil(control.physical_variant)
	lu.assertIsNil(control.api_variant)

	lu.assertEquals(#control.inputs, 1)

	lu.assertEquals(#control.outputs, 1)
end

--- @private
--- @param expected string
--- @param max_length integer
function TestReadWriteRadio:validate_string(expected, max_length)
	local value = ""
	local current_address = moduleAddress
	for i = 1, max_length, 1 do
		value = value .. string.char(self.module.memoryMap.entries[current_address].allocations[i % 2 == 0 and 2 or 1].value)
		current_address = i % 2 == 0 and current_address + 2 or current_address
	end

	lu.assertEquals(value, expected)
end

function TestReadWriteRadio:testInputSetNoDecimal()
	local max_length = 7
	local decimal_places = 3
	self.module:defineReadWriteRadio(id, device_id, max_length, decimal_places, scale_factor, description)
	local input_processor = self.module.inputProcessors[id]

	input_processor("123456")

	lu.assertEquals(#Input_Processor_Device.set_frequencies, 1)
	local set_frequency = Input_Processor_Device.set_frequencies[1]
	lu.assertAlmostEquals(set_frequency, 123456000)

	local export_hook = self.module.exportHooks[1]
	export_hook(Input_Processor_Device)
	self:validate_string("123.456", max_length)
end

function TestReadWriteRadio:testInputSetWithDecimal()
	local max_length = 7
	local decimal_places = 3
	self.module:defineReadWriteRadio(id, device_id, max_length, decimal_places, scale_factor, description)
	local input_processor = self.module.inputProcessors[id]

	input_processor("123.456")

	lu.assertEquals(#Input_Processor_Device.set_frequencies, 1)
	local set_frequency = Input_Processor_Device.set_frequencies[1]
	lu.assertAlmostEquals(set_frequency, 123456000)

	local export_hook = self.module.exportHooks[1]
	export_hook(Input_Processor_Device)
	self:validate_string("123.456", max_length)
end

function TestReadWriteRadio:testInputSetWithIncompleteDecimal()
	local max_length = 7
	local decimal_places = 3
	self.module:defineReadWriteRadio(id, device_id, max_length, decimal_places, scale_factor, description)
	local input_processor = self.module.inputProcessors[id]

	input_processor("123.4")

	lu.assertEquals(#Input_Processor_Device.set_frequencies, 1)
	local set_frequency = Input_Processor_Device.set_frequencies[1]
	lu.assertAlmostEquals(set_frequency, 123400000)

	local export_hook = self.module.exportHooks[1]
	export_hook(Input_Processor_Device)
	self:validate_string("123.400", max_length)
end

function TestReadWriteRadio:testInputSet4Digit()
	local max_length = 5
	local decimal_places = 2
	self.module:defineReadWriteRadio(id, device_id, max_length, decimal_places, scale_factor, description)
	local input_processor = self.module.inputProcessors[id]

	input_processor("30.00")

	lu.assertEquals(#Input_Processor_Device.set_frequencies, 1)
	local set_frequency = Input_Processor_Device.set_frequencies[1]
	lu.assertAlmostEquals(set_frequency, 3000000)

	local export_hook = self.module.exportHooks[1]
	export_hook(Input_Processor_Device)
	self:validate_string("30.00", max_length)
end
