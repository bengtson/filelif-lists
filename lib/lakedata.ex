defmodule LakeData do
	@moduledoc """
	Functions that relate to the water level at Lake Sara.
	"""
	@doc """
	Generates Lake Data based on measured parameters.

	Given a dock measurement and a water temperature measurement, the parameters for sending to the Lake Sara website are generated.

	The calculation for the water level ASL is: 581.72-(seawall+3.0)/12.0

	This equation is based on the survey height of the top of the doc at 581.72 feet above sealevel. The dock is 3" higher than the seawall. Given the seawall height above the water in inches, + 3 inches to the top of the dock, then converted to feet and subtracted from the feet above sealevel gives the current level of the water.
	"""
	def water_level_from_seawall (seawall) do
		581.72-(seawall+3.0)/12.0
#		IO.puts "Lake Level: " <> to_string(waterlevel)
	end
end
