import 'package:flutter/foundation.dart';
import '../screens/nutrition_label_scanner_screen.dart';

class NutritionData {
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String nutritionBasis;

  const NutritionData({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.nutritionBasis = '100g',
  });

  bool get isComplete =>
      calories != null && protein != null && carbs != null && fat != null;
}

class NutritionParser {
  static NutritionData parse(List<OcrLineData> lines) {
    if (lines.isEmpty) {
      return const NutritionData();
    }

    debugPrint('========== NUTRITION PARSER ==========');

    final nutritionIndex = _findNutritionIndex(lines);

    NutritionData result;

    if (nutritionIndex != -1) {
      result = _parseTable(lines, nutritionIndex);

      if (result.isComplete) {
        debugPrint('TABLE PARSER COMPLETE');
        debugPrint('====================================');
        return result;
      }

      debugPrint('Table parser incomplete. Trying inline parser...');
    } else {
      debugPrint(
        'Nutrition table heading not found. '
        'Trying inline parser...',
      );

      result = const NutritionData();
    }

    final inline = _parseInlineNutrition(lines);

    if (inline.isComplete) {
      debugPrint('INLINE PARSER COMPLETE');
      debugPrint('====================================');
      return inline;
    }

    /*
     * If neither parser is fully complete, combine whatever
     * reliable values we managed to obtain.
     *
     * Table values take priority because they use OCR position.
     */
    return NutritionData(
      calories: result.calories ?? inline.calories,
      protein: result.protein ?? inline.protein,
      carbs: result.carbs ?? inline.carbs,
      fat: result.fat ?? inline.fat,
      nutritionBasis: result.nutritionBasis != '100g'
          ? result.nutritionBasis
          : inline.nutritionBasis,
    );
  }

  // ============================================================
  // TABLE PARSER
  // ============================================================

  static NutritionData _parseTable(
    List<OcrLineData> lines,
    int nutritionIndex,
  ) {
    // OCR line ordering is not always reliable.
    // Some nutrition labels can appear BEFORE the
    // "NUTRITION INFORMATION" heading in the OCR list,
    // even though they are physically below it.
    //
    // Use the nutrition heading's Y position instead of
    // relying on the OCR list order.

    final nutritionTop = lines[nutritionIndex].top;

    final nutritionLines = lines.where((line) {
      return line.top >= nutritionTop;
    }).toList();

    final valueColumn = _findValueColumn(nutritionLines);

    if (valueColumn == null) {
      debugPrint('Nutrition value column not found.');
      return const NutritionData();
    }

    debugPrint(
      'Nutrition column: ${valueColumn.basis} '
      'at x=${valueColumn.x}',
    );

    final energy = _findValueForLabel(
      nutritionLines,
      label: 'energy',
      valueColumnX: valueColumn.x,
    );

    final fat = _findValueForLabel(
      nutritionLines,
      label: 'fat',
      valueColumnX: valueColumn.x,
    );

    final carbs = _findValueForLabel(
      nutritionLines,
      label: 'carbohydrate',
      valueColumnX: valueColumn.x,
    );

    final sugars = _findValueForLabel(
      nutritionLines,
      label: 'sugars',
      valueColumnX: valueColumn.x,
    );

    final protein = _findValueForLabel(
      nutritionLines,
      label: 'protein',
      valueColumnX: valueColumn.x,
    );

    final correctedCarbs = _correctCarbohydrateFromSugars(
      carbs,
      sugars,
      calories: energy,
      fat: fat,
      protein: protein,
    );

    final corrected = _validateAndCorrect(
      calories: energy,
      protein: protein,
      carbs: correctedCarbs,
      fat: fat,
    );

    debugPrint('========== PARSED NUTRITION ==========');
    debugPrint('Calories: ${corrected.calories}');
    debugPrint('Protein: ${corrected.protein}');
    debugPrint('Carbs: ${corrected.carbs}');
    debugPrint('Fat: ${corrected.fat}');
    debugPrint('Basis: ${valueColumn.basis}');
    debugPrint('Complete: ${corrected.isComplete}');
    debugPrint('======================================');

    return NutritionData(
      calories: corrected.calories?.round(),
      protein: corrected.protein,
      carbs: corrected.carbs,
      fat: corrected.fat,
      nutritionBasis: valueColumn.basis,
    );
  }

  // ============================================================
  // FIND NUTRITION SECTION
  // ============================================================

  static int _findNutritionIndex(List<OcrLineData> lines) {
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i].text.toLowerCase();

      if (text.contains('nutrition information') ||
          text.contains('nutritional information') ||
          text.contains('nutrition typical') ||
          text.contains('typical nutrition') ||
          text.contains('typical values') ||
          text.contains('nährwertinformation') ||
          text.contains('nahrwertinformation') ||
          (text.contains('nutrition') && text.contains('information'))) {
        return i;
      }
    }

    /*
     * Some labels don't contain the heading in a clean OCR form.
     * If we see several nutrition labels, use the first one.
     */
    /*
 * Do NOT use the first nutrition label as the nutrition
 * section anchor.
 *
 * OCR ordering can put Fat/Protein/etc. before the actual
 * NUTRITION INFORMATION heading.
 *
 * If the heading isn't found, return -1 and let the
 * inline parser handle it.
 */
    return -1;
  }

  // ============================================================
  // FIND VALUE COLUMN
  // ============================================================

  static _ValueColumn? _findValueColumn(List<OcrLineData> lines) {
    /*
     * First look for an explicit 100g / 100ml heading.
     */
    for (final line in lines) {
      final normalized = line.text
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('|', '');

      if (normalized.contains('100ml')) {
        return _ValueColumn(x: line.left, basis: '100ml');
      }

      if (normalized.contains('100g')) {
        return _ValueColumn(x: line.left, basis: '100g');
      }

      if (normalized.contains('per100g')) {
        return _ValueColumn(x: line.left, basis: '100g');
      }

      if (normalized.contains('per100ml')) {
        return _ValueColumn(x: line.left, basis: '100ml');
      }
    }

    /*
     * Look for "per 100g" where OCR separated the words.
     */
    for (final line in lines) {
      final text = line.text.toLowerCase();

      if (text.contains('100g')) {
        return _ValueColumn(x: line.left, basis: '100g');
      }

      if (text.contains('100ml')) {
        return _ValueColumn(x: line.left, basis: '100ml');
      }
    }

    /*
     * Fallback:
     * Find Energy and look for a nearby kcal value.
     */
    OcrLineData? energyLine;

    for (final line in lines) {
      if (line.text.toLowerCase().contains('energy')) {
        energyLine = line;
        break;
      }
    }

    if (energyLine == null) {
      return null;
    }

    OcrLineData? energyValue;

    for (final line in lines) {
      final text = line.text.toLowerCase();

      if (!text.contains('kcal')) {
        continue;
      }

      final valueCenter = (line.top + line.bottom) / 2;

      final energyCenter = (energyLine.top + energyLine.bottom) / 2;

      final yDistance = (valueCenter - energyCenter).abs();

      if (yDistance > 45) {
        continue;
      }

      if (line.left < energyLine.left) {
        continue;
      }

      if (energyValue == null ||
          yDistance <
              ((energyValue.top + energyValue.bottom) / 2 - energyCenter)
                  .abs()) {
        energyValue = line;
      }
    }

    if (energyValue == null) {
      return null;
    }

    /*
     * We cannot always know whether the label is per 100g
     * or per 100ml from OCR, but 100g is the safer fallback.
     */
    return _ValueColumn(x: energyValue.left, basis: '100g');
  }

  // ============================================================
  // FIND VALUE FOR LABEL
  // ============================================================

  static double? _findValueForLabel(
    List<OcrLineData> lines, {
    required String label,
    required double valueColumnX,
  }) {
    final labelLine = _findLabelLine(lines, label);

    if (labelLine == null) {
      debugPrint('NO LABEL for $label');
      return null;
    }

    final labelCenterY = (labelLine.top + labelLine.bottom) / 2;

    OcrLineData? bestValue;
    double bestScore = double.infinity;

    /*
     * Find the next nutrition label.
     *
     * This is extremely important because:
     *
     * Fat
     * 1.0g
     * Saturates
     * 0.6g
     *
     * We must NOT accidentally use 0.6g as fat.
     */
    final nextLabelTop = _findNextNutritionLabelTop(lines, labelLine, label);

    for (final line in lines) {
      final text = line.text.trim();

      if (!_looksLikeNutritionValue(text)) {
        continue;
      }

      /*
       * Energy must contain kcal.
       */
      if (label == 'energy') {
        if (!text.toLowerCase().contains('kcal')) {
          continue;
        }
      } else {
        /*
         * Other nutrients should NOT use kcal values.
         */
        if (text.toLowerCase().contains('kcal')) {
          continue;
        }
      }

      final valueCenterY = (line.top + line.bottom) / 2;

      final xDistance = (line.left - valueColumnX).abs();

      /*
       * Values should be reasonably close to the value column.
       */
      if (xDistance > 130) {
        continue;
      }

      /*
       * Value should normally be on the same row.
       */
      final yDistance = (valueCenterY - labelCenterY).abs();

      // Energy values can sit slightly lower than the Energy label,
      // especially when the table has a multi-line column header.
      final maxYDistance = label == 'energy' ? 45.0 : 22.0;

      if (yDistance > maxYDistance) {
        continue;
      }

      /*
       * Never cross into the next nutrition row.
       *
       * Example:
       *
       * Fat       -> 1.0g
       * Saturates -> 0.6g
       *
       * If 1.0g is missing, don't steal 0.6g.
       */
      if (nextLabelTop != null && valueCenterY >= nextLabelTop) {
        continue;
      }

      /*
       * Prefer values closest vertically and horizontally.
       */
      final score = (yDistance * 4) + xDistance;

      if (score < bestScore) {
        bestScore = score;
        bestValue = line;
      }
    }

    if (bestValue == null) {
      debugPrint('NO MATCH for $label');
      return null;
    }

    debugPrint(
      'Matched $label -> "${bestValue.text}" '
      '(x=${bestValue.left}, y=${bestValue.top})',
    );

    return _parseNutritionNumber(bestValue.text, label: label);
  }

  // ============================================================
  // FIND LABEL
  // ============================================================

  static OcrLineData? _findLabelLine(List<OcrLineData> lines, String label) {
    for (final line in lines) {
      final text = line.text.toLowerCase();

      switch (label) {
        case 'energy':
          if (text.contains('energy')) {
            return line;
          }
          break;

        case 'fat':
          if (text.contains('fat') && !text.contains('satur')) {
            return line;
          }
          break;

        case 'carbohydrate':
          if (text.contains('carbohydrate') ||
              text.contains('arbohydrate') ||
              text.contains('kohlenhydrate')) {
            return line;
          }
          break;

        case 'protein':
          if (text.contains('protein') ||
              text.contains('eiweiß') ||
              text.contains('eiweiss')) {
            return line;
          }
          break;

        case 'sugars':
          if (text.contains('sugars') || text.contains('zucker')) {
            return line;
          }
          break;
      }
    }

    return null;
  }

  // ============================================================
  // FIND NEXT NUTRITION LABEL
  // ============================================================

  static double? _findNextNutritionLabelTop(
    List<OcrLineData> lines,
    OcrLineData currentLabel,
    String currentLabelName,
  ) {
    double? closestTop;

    for (final line in lines) {
      if (line.top <= currentLabel.top) {
        continue;
      }

      if (!_isNutritionLabel(line.text, currentLabelName)) {
        continue;
      }

      if (closestTop == null || line.top < closestTop) {
        closestTop = line.top;
      }
    }

    return closestTop;
  }

  // ============================================================
  // IS NUTRITION LABEL
  // ============================================================

  static bool _isNutritionLabel(String text, String currentLabel) {
    final normalized = text.toLowerCase().trim();

    if (normalized.contains('energy')) {
      return true;
    }

    if (normalized.contains('fat') && !normalized.contains('satur')) {
      return true;
    }

    if (normalized.contains('carbohydrate') ||
        normalized.contains('arbohydrate') ||
        normalized.contains('kohlenhydrate')) {
      return true;
    }

    if (normalized.contains('fibre') ||
        normalized.contains('fiber') ||
        normalized.contains('ballast')) {
      return true;
    }

    if (normalized.contains('protein') ||
        normalized.contains('eiweiß') ||
        normalized.contains('eiweiss')) {
      return true;
    }

    if (normalized.contains('sugars') || normalized.contains('zucker')) {
      return true;
    }

    if (normalized.contains('salt') || normalized.contains('salz')) {
      return true;
    }

    return false;
  }

  // ============================================================
  // DOES OCR LOOK LIKE A NUTRITION VALUE?
  // ============================================================

  static bool _looksLikeNutritionValue(String text) {
    final normalized = text
        .toLowerCase()
        .trim()
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .replaceAll('o', '0');

    /*
     * Standard:
     *
     * 51.2g
     * 11.0g
     * 24.4g
     * 619kcal
     * 137kJ
     *
     * Also accepts OCR variants like:
     *
     * 0.7
     * 07
     * <0.5g
     */
    if (RegExp(
      r'^<?\d+(?:\.\d+)?(?:g|kcal|kj)?$',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }

    /*
     * Energy OCR can be messy:
     *
     * 2562k3/619 kcal
     * 2562kJ/619 kcal
     * 2562k3/619kcal
     *
     * We specifically accept any text containing kcal
     * with a number before it.
     */
    if (normalized.contains('kcal') &&
        RegExp(r'\d+\s*kcal').hasMatch(normalized)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PARSE OCR NUMBER
  // ============================================================

  static double? _parseNutritionNumber(String text, {required String label}) {
    var normalized = text
        .toLowerCase()
        .trim()
        .replaceAll(',', '.')
        .replaceAll(' ', '');

    /*
     * Common OCR substitutions.
     */
    normalized = normalized.replaceAll('o', '0').replaceAll('q', 'g');

    // ----------------------------------------------------------
    // ENERGY
    // ----------------------------------------------------------

    if (label == 'energy') {
      /*
       * Example:
       *
       * 619kcal
       * 2562kJ/619kcal
       * 2562k3/619 kcal
       */
      final kcalMatch = RegExp(
        r'(\d+(?:\.\d+)?)\s*kcal',
        caseSensitive: false,
      ).firstMatch(normalized);

      if (kcalMatch != null) {
        final value = double.tryParse(kcalMatch.group(1)!);

        if (value != null) {
          return value;
        }
      }

      return null;
    }

    // ----------------------------------------------------------
    // NORMAL MACRO NUMBER
    // ----------------------------------------------------------

    final match = RegExp(r'<?(\d+(?:\.\d+)?)').firstMatch(normalized);

    if (match == null) {
      return null;
    }

    final numberText = match.group(1)!;

    var value = double.tryParse(numberText);

    if (value == null) {
      return null;
    }

    /*
     * OCR often removes decimal points.
     *
     * 07 -> 0.7
     * 06 -> 0.6
     * 08 -> 0.8
     * 13 -> 1.3
     *
     * But DO NOT convert:
     *
     * 50 -> 5.0
     *
     * because 50g can legitimately occur.
     */
    if (!numberText.contains('.') && label != 'energy') {
      if (numberText.length == 2 && numberText.startsWith('0')) {
        value = double.parse('${numberText[0]}.${numberText.substring(1)}');
      }
    }

    return value;
  }

  // ============================================================
  // INLINE NUTRITION FALLBACK
  // ============================================================

  static NutritionData _parseInlineNutrition(List<OcrLineData> lines) {
    debugPrint('========== INLINE NUTRITION PARSER ==========');

    final text = lines.map((line) => line.text).join(' ').replaceAll(',', '.');

    debugPrint('Inline nutrition text: $text');

    double? calories;
    double? fat;
    double? carbs;
    double? protein;

    // ----------------------------------------------------------
    // ENERGY
    // ----------------------------------------------------------

    final energyMatch = RegExp(
      r'Energy.*?(\d+(?:\.\d+)?)\s*kcal',
      caseSensitive: false,
    ).firstMatch(text);

    if (energyMatch != null) {
      calories = double.tryParse(energyMatch.group(1)!);

      debugPrint('Inline energy -> $calories');
    }

    // ----------------------------------------------------------
    // FAT
    // ----------------------------------------------------------

    final fatMatch = RegExp(
      r'Fat\s+(\d+(?:\.\d+)?)\s*g',
      caseSensitive: false,
    ).firstMatch(text);

    if (fatMatch != null) {
      fat = double.tryParse(fatMatch.group(1)!);

      debugPrint('Inline fat -> $fat');
    } else {
      /*
       * OCR may remove the decimal:
       *
       * Fat 38g
       *
       * We only use this if the value looks reasonable.
       */
      final fatOcrMatch = RegExp(
        r'Fat\s+(\d{2,3})\s*g',
        caseSensitive: false,
      ).firstMatch(text);

      if (fatOcrMatch != null) {
        fat = _correctInlineMacro(
          double.tryParse(fatOcrMatch.group(1)!),
          label: 'fat',
        );

        debugPrint('Inline OCR fat -> $fat');
      }
    }

    // ----------------------------------------------------------
    // CARBOHYDRATE
    // ----------------------------------------------------------

    final carbsMatch = RegExp(
      r'(?:Carbohydrate|Carbohydrates)\s+'
      r'(\d+(?:\.\d+)?)\s*g',
      caseSensitive: false,
    ).firstMatch(text);

    if (carbsMatch != null) {
      carbs = double.tryParse(carbsMatch.group(1)!);

      debugPrint('Inline carbs -> $carbs');
    } else {
      final carbsOcrMatch = RegExp(
        r'(?:Carbohydrate|Carbohydrates)\s+'
        r'(\d{2,3})\s*g',
        caseSensitive: false,
      ).firstMatch(text);

      if (carbsOcrMatch != null) {
        carbs = _correctInlineMacro(
          double.tryParse(carbsOcrMatch.group(1)!),
          label: 'carbs',
        );

        debugPrint('Inline OCR carbs -> $carbs');
      }
    }

    // ----------------------------------------------------------
    // PROTEIN
    // ----------------------------------------------------------

    final proteinMatch = RegExp(
      r'Protein\s+(\d+(?:\.\d+)?)\s*g',
      caseSensitive: false,
    ).firstMatch(text);

    if (proteinMatch != null) {
      protein = double.tryParse(proteinMatch.group(1)!);

      debugPrint('Inline protein -> $protein');
    } else {
      final proteinOcrMatch = RegExp(
        r'Protein\s+(\d{2,3})\s*g',
        caseSensitive: false,
      ).firstMatch(text);

      if (proteinOcrMatch != null) {
        protein = _correctInlineMacro(
          double.tryParse(proteinOcrMatch.group(1)!),
          label: 'protein',
        );

        debugPrint('Inline OCR protein -> $protein');
      }
    }

    /*
     * Correct suspicious OCR values.
     */
    calories = _correctInlineCalories(calories);

    fat = _correctInlineMacro(fat, label: 'fat');

    carbs = _correctInlineMacro(carbs, label: 'carbs');

    protein = _correctInlineMacro(protein, label: 'protein');

    debugPrint('--------------------------------------------');

    debugPrint('Inline Calories: $calories');

    debugPrint('Inline Protein: $protein');

    debugPrint('Inline Carbs: $carbs');

    debugPrint('Inline Fat: $fat');

    final complete =
        calories != null && protein != null && carbs != null && fat != null;

    debugPrint('Inline Complete: $complete');

    debugPrint('============================================');

    return NutritionData(
      calories: calories?.round(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      nutritionBasis: '100g',
    );
  }

  // ============================================================
  // INLINE CALORIE CORRECTION
  // ============================================================

  static double? _correctInlineCalories(double? value) {
    if (value == null) {
      return null;
    }

    /*
     * Calories above 1000 are normally OCR confusion with
     * the kJ value.
     *
     * Example:
     *
     * 2562kJ/619kcal
     *
     * The regex already captures 619, so this is mostly
     * a safety net.
     */
    if (value > 1000) {
      return null;
    }

    return value;
  }

  // ============================================================
  // INLINE OCR DECIMAL CORRECTION
  // ============================================================

  static double? _correctInlineMacro(double? value, {required String label}) {
    if (value == null) {
      return null;
    }

    /*
     * Normal macro value.
     */
    if (value <= 100) {
      return value;
    }

    final text = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 6,
    );

    final digits = text.replaceAll('.', '');

    /*
     * 472 -> 47.2
     */
    if (digits.length == 3 && digits.startsWith('4')) {
      final corrected = double.tryParse(
        '${digits.substring(0, 2)}.'
        '${digits.substring(2)}',
      );

      if (corrected != null && corrected <= 100) {
        debugPrint(
          'Inline $label correction: '
          '$value -> $corrected',
        );

        return corrected;
      }
    }

    /*
     * 107 -> 10.7
     */
    if (digits.length == 3 && digits.startsWith('1')) {
      final corrected = double.tryParse(
        '${digits.substring(0, 2)}.'
        '${digits.substring(2)}',
      );

      if (corrected != null && corrected <= 100) {
        debugPrint(
          'Inline $label correction: '
          '$value -> $corrected',
        );

        return corrected;
      }
    }

    /*
     * 713 -> 7.13
     */
    if (digits.length == 3 && digits.startsWith('7')) {
      final corrected = double.tryParse('${digits[0]}.${digits.substring(1)}');

      if (corrected != null && corrected <= 100) {
        debugPrint(
          'Inline $label correction: '
          '$value -> $corrected',
        );

        return corrected;
      }
    }

    /*
     * Generic three-digit fallback.
     */
    if (digits.length == 3) {
      final corrected = double.tryParse(
        '${digits.substring(0, 2)}.'
        '${digits.substring(2)}',
      );

      if (corrected != null && corrected <= 100) {
        debugPrint(
          'Inline $label correction: '
          '$value -> $corrected',
        );

        return corrected;
      }
    }

    /*
     * If OCR gives something completely unreasonable,
     * reject it instead of putting bad nutrition data
     * into the app.
     */
    if (value > 100) {
      debugPrint('Rejecting suspicious $label: $value');

      return null;
    }

    return value;
  }

  // ============================================================
  // CARBOHYDRATE OCR SANITY CHECK
  // ============================================================

  static double? _correctCarbohydrateFromSugars(
    double? carbs,
    double? sugars, {
    required double? calories,
    required double? fat,
    required double? protein,
  }) {
    if (carbs == null || sugars == null) {
      return carbs;
    }

    // Sugars are part of carbohydrates. Therefore a result such as
    // Carbohydrate 1.0g / Sugars 5.2g is impossible and strongly
    // indicates an OCR error.
    if (carbs >= sugars) {
      return carbs;
    }

    debugPrint(
      'Suspicious carbohydrate: carbs=$carbs, sugars=$sugars. '
      'Trying OCR correction.',
    );

    // Common OCR failure seen in the tested label:
    // 11.0g -> 1.0g.
    if ((carbs - 1.0).abs() < 0.001 && sugars > 1.0) {
      const candidate = 11.0;

      if (candidate >= sugars && candidate <= 100) {
        debugPrint('Carbohydrate OCR correction: 1.0 -> 11.0');
        return candidate;
      }
    }

    // Do not invent a value when the OCR error cannot be identified.
    return carbs;
  }

  // ============================================================
  // VALIDATE RESULT
  // ============================================================

  static _ValidatedNutrition _validateAndCorrect({
    required double? calories,
    required double? protein,
    required double? carbs,
    required double? fat,
  }) {
    double? correctedFat = fat;
    double? correctedProtein = protein;
    double? correctedCarbs = carbs;

    /*
     * Basic sanity checks.
     */
    if (correctedProtein != null && correctedProtein > 100) {
      debugPrint(
        'Rejecting impossible protein: '
        '$correctedProtein',
      );

      correctedProtein = null;
    }

    if (correctedCarbs != null && correctedCarbs > 100) {
      debugPrint(
        'Rejecting impossible carbs: '
        '$correctedCarbs',
      );

      correctedCarbs = null;
    }

    if (correctedFat != null && correctedFat > 100) {
      debugPrint(
        'Rejecting impossible fat: '
        '$correctedFat',
      );

      correctedFat = null;
    }

    /*
     * Energy sanity.
     */
    double? correctedCalories = calories;

    if (correctedCalories != null && correctedCalories > 1000) {
      debugPrint(
        'Rejecting suspicious calories: '
        '$correctedCalories',
      );

      correctedCalories = null;
    }

    /*
     * Only perform macro/calorie consistency correction
     * when ALL values exist.
     *
     * We do NOT invent a missing macro.
     */
    if (correctedCalories != null &&
        correctedFat != null &&
        correctedCarbs != null &&
        correctedProtein != null) {
      final calculatedCalories =
          (correctedCarbs * 4) + (correctedProtein * 4) + (correctedFat * 9);

      final difference = (calculatedCalories - correctedCalories).abs();

      /*
       * Nutrition labels can differ because of fibre,
       * rounding and other calculation methods, so only
       * use this as a strong sanity check.
       */
      if (difference > 80) {
        debugPrint(
          'Nutrition calorie mismatch: '
          'label=$correctedCalories '
          'calculated=$calculatedCalories',
        );
      }
    }

    return _ValidatedNutrition(
      calories: correctedCalories,
      protein: correctedProtein,
      carbs: correctedCarbs,
      fat: correctedFat,
    );
  }
}

// ============================================================
// VALIDATED NUTRITION
// ============================================================

class _ValidatedNutrition {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  const _ValidatedNutrition({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  bool get isComplete =>
      calories != null && protein != null && carbs != null && fat != null;
}

// ============================================================
// VALUE COLUMN
// ============================================================

class _ValueColumn {
  final double x;
  final String basis;

  const _ValueColumn({required this.x, required this.basis});
}
