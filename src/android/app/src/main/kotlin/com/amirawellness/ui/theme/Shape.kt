package com.amirawellness.ui.theme

import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Shapes
import androidx.compose.ui.unit.dp

/**
 * Standard corner radius constants used throughout the application.
 * These values help maintain consistency in the UI design.
 */
val SmallRadius = 4.dp
val MediumRadius = 8.dp
val LargeRadius = 16.dp
val ExtraLargeRadius = 24.dp

/**
 * Predefined shapes for specific UI components.
 * Each component has an appropriate corner radius to support the 
 * minimalist, nature-inspired design approach.
 */
val CardShape = RoundedCornerShape(MediumRadius)
val ButtonShape = RoundedCornerShape(MediumRadius)
val InputFieldShape = RoundedCornerShape(SmallRadius)
val BottomSheetShape = RoundedCornerShape(topStart = LargeRadius, topEnd = LargeRadius)
val DialogShape = RoundedCornerShape(LargeRadius)
val ChipShape = RoundedCornerShape(percent = 50) // Pill shape for chips

/**
 * Material Design shapes for Amira Wellness application.
 * These shapes apply rounded corners with different radii based on component size.
 * These rounded corners contribute to the calming, nature-inspired aesthetic
 * that is central to the application's design philosophy.
 */
val Shapes = Shapes(
    small = RoundedCornerShape(SmallRadius),
    medium = RoundedCornerShape(MediumRadius),
    large = RoundedCornerShape(LargeRadius)
)