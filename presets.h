int active_preset = 0;
#define N_PRESETS 3
// a nice starting configuration
const preset presets[N_PRESETS]= {
	{ // nice flower
		B_DEAD,
		S_PRESET,
		{
			{ 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 1, 0, 0, 0 },
			{ 0, 1, 1, 1, 0, 0, 0 },
			{ 0, 0, 0, 1, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0 },
		}
	},
	{ // glider
		B_WRAPPED,
		S_PRESET,
		{
			{ 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 1, 0, 0, 0, 0 },
			{ 0, 0, 0, 1, 0, 0, 0 },
			{ 0, 1, 1, 1, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0 },
		}
	},
	{ // random stuff
		B_DEAD,
		S_RANDOM,
		{
			{ 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0 },
		}
	},
};
