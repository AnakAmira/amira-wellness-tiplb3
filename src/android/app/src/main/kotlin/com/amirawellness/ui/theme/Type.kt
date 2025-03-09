package com.amirawellness.ui.theme

import androidx.compose.material.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.TextPrimary
import androidx.compose.ui.graphics.TextSecondary

/**
 * Typography definition for Amira Wellness application
 * 
 * This file establishes a consistent typography system with a clean, readable
 * sans-serif font family that supports the application's minimalist, 
 * nature-inspired design approach for emotional wellness.
 * 
 * The typography follows Material Design guidelines with appropriate
 * adjustments to create a calm, trustworthy interface through careful
 * selection of font weights, sizes, and line heights.
 */

/**
 * Primary font family used throughout the application
 * 
 * Using the system sans-serif font family ensures good readability
 * across all Android devices while maintaining a clean, modern aesthetic.
 */
val SansSerifFontFamily = FontFamily.SansSerif

/**
 * Complete typography system for the Amira Wellness application
 * 
 * Each text style is carefully defined with appropriate size, weight,
 * letter spacing, and line height to ensure readability and visual hierarchy
 * throughout the application.
 */
val Typography = Typography(
    h1 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Light,
        fontSize = 96.sp,
        letterSpacing = (-1.5).sp,
        color = TextPrimary
    ),
    h2 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Light,
        fontSize = 60.sp,
        letterSpacing = (-0.5).sp,
        color = TextPrimary
    ),
    h3 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 48.sp,
        letterSpacing = 0.sp,
        color = TextPrimary
    ),
    h4 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 34.sp,
        letterSpacing = 0.25.sp,
        color = TextPrimary
    ),
    h5 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 24.sp,
        letterSpacing = 0.sp,
        color = TextPrimary
    ),
    h6 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 20.sp,
        letterSpacing = 0.15.sp,
        color = TextPrimary
    ),
    subtitle1 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        letterSpacing = 0.15.sp,
        color = TextPrimary
    ),
    subtitle2 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        letterSpacing = 0.1.sp,
        color = TextPrimary
    ),
    body1 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        letterSpacing = 0.5.sp,
        color = TextPrimary,
        lineHeight = 24.sp
    ),
    body2 = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        letterSpacing = 0.25.sp,
        color = TextSecondary,
        lineHeight = 20.sp
    ),
    button = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        letterSpacing = 1.25.sp,
        color = TextPrimary
    ),
    caption = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        letterSpacing = 0.4.sp,
        color = TextSecondary
    ),
    overline = TextStyle(
        fontFamily = SansSerifFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 10.sp,
        letterSpacing = 1.5.sp,
        color = TextSecondary
    )
)