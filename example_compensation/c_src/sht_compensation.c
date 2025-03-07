// SPDX-FileCopyrightText: 2023 Digit
//
// SPDX-License-Identifier: Apache-2.0
//
// Example Compensation Algorithm
//
// Actual source code in this file would be provided by Sensirion AG

#include "sht_compensation.h"

float v[25] = {0};

void sht_compensate_every_5_seconds(float temperature_sht, float humidity_sht, float status_LCD_brightness, float status_CPU_LOAD, float *temperature_ambient, float *humidity_ambient)
{
    // For example purposes, adjust the temperature by v[0] and humidity by v[1].
    // The real computation is way more complicated.

    *temperature_ambient = (float) (temperature_sht + v[0]);
    *humidity_ambient = (float) (humidity_sht + v[1]);
}
