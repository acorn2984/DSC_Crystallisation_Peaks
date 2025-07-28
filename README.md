# DSC Isothermal Crystallization Analysis

A MATLAB tool for analyzing Differential Scanning Calorimetry (DSC) data during isothermal crystallization experiments.

## Overview

This tool processes DSC data from isothermal crystallization experiments where samples are:
1. Heated from 25°C to 300°C at 10°C/min
2. Held at 300°C for 3 minutes
3. Cooled from 300°C to target temperature at 50°C/min
4. Held at target temperature for 140 minutes (isothermal crystallization)

The analysis automatically identifies the first minimum after the isothermal period begins and uses this as the origin for crystallization kinetics analysis.

## Features

- **Flexible temperature analysis**: Supports any number of target temperatures
- **Automatic timing calculation**: Calculates isothermal start times based on heating/cooling rates
- **Origin normalization**: Sets first minimum as (0,0) for each temperature curve
- **Crystallization detection**: Automatically identifies crystallization completion times
- **Multi-scale visualization**: Three complementary views (140 min, 120 min, 60 min)
- **Professional plotting**: Enhanced grids and formatting for publication-quality figures

## Requirements

- MATLAB R2019b or later
- Signal Processing Toolbox (for `smoothdata` function)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/dsc-isothermal-analysis.git
```

2. Add the folder to your MATLAB path or navigate to the folder in MATLAB

## Usage

1. Prepare your DSC data files in text format with columns:
   - Column 1: Index
   - Column 2: Time (seconds)
   - Column 3: Heat Flow (W/g)
   - Column 4: Sample Temperature (°C)
   - Column 5: Reference Temperature (°C)

2. Run the main script:
```matlab
dsc_isothermal_analysis
```

3. Follow the interactive prompts:
   - Enter material name
   - Specify number of target temperatures
   - Provide target temperatures and corresponding file names

## Output

The tool generates:

### Plots
- **Plot 1**: Complete 140-minute isothermal hold (raw data)
- **Plot 2**: 0-120 minutes from first minimum (normalized)
- **Plot 3**: 0-60 minutes from first minimum (zoomed view)

### Data
- Crystallization times for each temperature
- Summary table with results
- Saved MATLAB workspace (.mat file) with all processed data

### Console Output
```
=== ISOTHERMAL CRYSTALLIZATION ANALYSIS RESULTS ===
Material: PA410 GF50 High MW
Temperature  Crystallization Time  Crystallization Time
(°C)         (seconds)            (minutes)
--------     ----------------     ----------------
245          1245.60              20.76
247          1890.30              31.51
250          Not detected         Not detected
```

## Algorithm Details

### Timing Calculation
The isothermal start time for each temperature is calculated as:
```
isothermal_start = heating_time + hold_300_time + cooling_time
where:
- heating_time = (300-25)/10 * 60 = 1650 seconds
- hold_300_time = 3 * 60 = 180 seconds  
- cooling_time = (300-target_temp)/50 * 60 seconds
```

### Origin Normalization
1. Identifies first minimum in heat flow after isothermal period begins
2. Sets this minimum as time = 0 and heat flow = 0
3. All subsequent data points are relative to this origin

### Crystallization Detection
Uses a smoothed minimum-finding algorithm to detect when crystallization is complete (plateau reached).

## File Structure

```
dsc-isothermal-analysis/
├── README.md
├── LICENSE
├── dsc_isothermal_analysis.m     # Main analysis script
└── examples/
    ├── sample_data_245C.txt      # Example DSC data file
    ├── sample_data_247C.txt
    └── sample_data_250C.txt
```

## Example Data Format

```
Index    Time(s)    HeatFlow(W/g)    Ts(°C)    Tr(°C)
1        0.0        0.0245           25.1      25.0
2        1.0        0.0248           25.2      25.0
3        2.0        0.0251           25.3      25.0
...
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Guidelines
- Follow MATLAB coding standards
- Add comments for complex algorithms
- Test with various DSC data formats
- Update documentation for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use this tool in your research, please cite:

```bibtex
@software{dsc_isothermal_analysis,
  title = {DSC Isothermal Crystallization Analysis},
  author = {Anjali Malik},
  year = {2025},
  url = {https://github.com/yourusername/dsc-isothermal-analysis},
  version = {1.0.0}
}
```

## Troubleshooting

### Common Issues

**Error: "Cannot find isothermal start time"**
- Check that your data contains the complete thermal cycle
- Verify time units are in seconds
- Ensure target temperature is reasonable (< 300°C)

**Error: "No minimum found"**
- Data may be too noisy - try increasing smoothing window
- Check that isothermal period actually exists in your data
- Verify heat flow units and sign convention

**Plots look incorrect**
- Verify column order in your data files
- Check heat flow sign convention (exothermic up/down)
- Ensure temperature and time units match expectations

## Support

For questions or issues:
1. Check the troubleshooting section above
2. Search existing [GitHub Issues](https://github.com/yourusername/dsc-isothermal-analysis/issues)
3. Create a new issue with:
   - MATLAB version
   - Sample data file (if possible)
   - Error messages
   - Expected vs actual behavior

## Acknowledgments

- Developed for polymer crystallization kinetics research
- Thanks to the materials science community for feedback and testing
