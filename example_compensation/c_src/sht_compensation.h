// Example Compensation Algorithm
//
// Actual source code in this file would be provided by Sensirion AG

#include "stdint.h"

#ifndef SHT_COMPENSATION_H
#define SHT_COMPENSATION_H

extern float v[25];

/**
 * Sensirion Temperature+Humidity Compensation. Must be executed every 5 seconds.
 *
 * @param temperature_sht       Temperature readout from SHT sensor (Units: C)
 * @param humidity_sht          Relative Humidity readout from SHT sensor (Units: rh)
 * @param status_LCD_brightness Example factor that could be computed into the compensation (Display current/brightness level)
 * @param status_CPU_LOAD       Example factor that could be computed into the compensation (CPU Usage)
 *
 * @param *temperature_ambient  pointer to a variable, where compensated temperature
 *                              should be stored
 * @param *humidity_ambient     pointer to a variable, where compensated relative
 *                              humidity should be stored
 **/
void sht_compensate_every_5_seconds(float temperature_sht, float humidity_sht, float status_LCD_brightness, float status_CPU_LOAD, float *temperature_ambient, float *humidity_ambient);

#endif /* SHT_COMPENSATION_H */
