import 'package:flutter_test/flutter_test.dart';
import 'package:recipesoup/models/ingredient.dart';

void main() {
  group('Ingredient Model Tests', () {
    test('should create ingredient with all fields', () {
      // Given & When
      final ingredient = Ingredient(
        name: '양파',
        amount: '1',
        unit: '개',
        category: IngredientCategory.vegetable,
      );
      
      // Then
      expect(ingredient.name, equals('양파'));
      expect(ingredient.amount, equals('1'));
      expect(ingredient.unit, equals('개'));
      expect(ingredient.category, equals(IngredientCategory.vegetable));
    });
    
    test('should create ingredient with minimal required fields', () {
      // Given & When
      final ingredient = Ingredient(
        name: '소금',
      );
      
      // Then
      expect(ingredient.name, equals('소금'));
      expect(ingredient.amount, isNull);
      expect(ingredient.unit, isNull);
      expect(ingredient.category, isNull);
    });
    
    test('should convert to JSON correctly', () {
      // Given
      final ingredient = Ingredient(
        name: '쇠고기',
        amount: '200',
        unit: 'g',
        category: IngredientCategory.meat,
      );
      
      // When
      final json = ingredient.toJson();
      
      // Then
      expect(json, equals({
        'name': '쇠고기',
        'amount': '200',
        'unit': 'g',
        'category': 'meat',
      }));
    });
    
    test('should create from JSON correctly', () {
      // Given
      final json = {
        'name': '감자',
        'amount': '2',
        'unit': '개',
        'category': 'vegetable',
      };
      
      // When
      final ingredient = Ingredient.fromJson(json);
      
      // Then
      expect(ingredient.name, equals('감자'));
      expect(ingredient.amount, equals('2'));
      expect(ingredient.unit, equals('개'));
      expect(ingredient.category, equals(IngredientCategory.vegetable));
    });
    
    test('should handle null category in JSON', () {
      // Given
      final json = {
        'name': '소금',
        'amount': '적당량',
      };
      
      // When
      final ingredient = Ingredient.fromJson(json);
      
      // Then
      expect(ingredient.name, equals('소금'));
      expect(ingredient.amount, equals('적당량'));
      expect(ingredient.unit, isNull);
      expect(ingredient.category, isNull);
    });
    
    test('should create copy with updated fields', () {
      // Given
      final original = Ingredient(
        name: '당근',
        amount: '1',
        unit: '개',
        category: IngredientCategory.vegetable,
      );
      
      // When
      final updated = original.copyWith(
        amount: '2',
        unit: '개',
      );
      
      // Then
      expect(updated.name, equals('당근')); // 변경되지 않음
      expect(updated.amount, equals('2')); // 변경됨
      expect(updated.unit, equals('개')); // 변경됨
      expect(updated.category, equals(IngredientCategory.vegetable)); // 변경되지 않음
    });
    
    test('should display correct string representation', () {
      // Given
      final ingredientWithUnit = Ingredient(
        name: '쌀',
        amount: '2',
        unit: '컵',
      );
      
      final ingredientWithoutUnit = Ingredient(
        name: '소금',
        amount: '적당량',
      );
      
      final ingredientNameOnly = Ingredient(
        name: '마늘',
      );
      
      // When & Then
      expect(ingredientWithUnit.displayText, equals('쌀 2컵'));
      expect(ingredientWithoutUnit.displayText, equals('소금 적당량'));
      expect(ingredientNameOnly.displayText, equals('마늘'));
    });
  });
  
  group('IngredientCategory Enum Tests', () {
    test('should have all required categories', () {
      // Given
      final expectedCategories = [
        'vegetable', 'meat', 'seafood', 'dairy', 
        'grain', 'seasoning', 'other'
      ];
      
      // When
      final actualCategories = IngredientCategory.values.map((c) => c.name).toList();
      
      // Then
      expect(actualCategories, equals(expectedCategories));
    });
    
    test('should convert to Korean display names', () {
      // Given & When & Then
      expect(IngredientCategory.vegetable.displayName, equals('채소'));
      expect(IngredientCategory.meat.displayName, equals('고기'));
      expect(IngredientCategory.seafood.displayName, equals('해산물'));
      expect(IngredientCategory.dairy.displayName, equals('유제품'));
      expect(IngredientCategory.grain.displayName, equals('곡물'));
      expect(IngredientCategory.seasoning.displayName, equals('조미료'));
      expect(IngredientCategory.other.displayName, equals('기타'));
    });
    
    test('should convert from string correctly', () {
      // Given & When & Then
      expect(IngredientCategory.fromString('vegetable'), 
             equals(IngredientCategory.vegetable));
      expect(IngredientCategory.fromString('meat'), 
             equals(IngredientCategory.meat));
      expect(IngredientCategory.fromString('invalid'), isNull);
    });
  });
}