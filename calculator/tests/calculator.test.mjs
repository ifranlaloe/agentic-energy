import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Calculator } from '../src/calculator.ts';

function enter(...keys) {
  const calculator = new Calculator();
  keys.forEach((key) => calculator.press(key));
  return calculator;
}

test('calculates addition, subtraction, multiplication and division', () => {
  assert.equal(enter('8', '+', '2', '=').display, '10');
  assert.equal(enter('8', '−', '2', '=').display, '6');
  assert.equal(enter('8', '×', '2', '=').display, '16');
  assert.equal(enter('8', '÷', '2', '=').display, '4');
});

test('handles decimal input without floating-point display noise', () => {
  const calculator = enter('0', '.', '1', '+', '0', '.', '2', '=');
  assert.equal(calculator.display, '0.3');
  assert.equal(calculator.expression, '0.1 + 0.2 =');
  assert.equal(enter('.', '5', '.', '5').display, '0.55');
});

test('replaces pending operators and chains calculations from left to right', () => {
  assert.equal(enter('9', '+', '×', '2', '=').display, '18');
  assert.equal(enter('2', '+', '3', '×', '4', '=').display, '20');
});

test('edits digits, clears state and starts a new calculation after equals', () => {
  const calculator = enter('1', '2', 'backspace');
  assert.equal(calculator.display, '1');
  calculator.press('clear');
  assert.equal(calculator.display, '0');
  assert.equal(enter('2', '+', '3', '=', '7').display, '7');
  assert.equal(enter('2', '+', '3', '=', '×', '2', '=').display, '10');
});

test('toggles sign and treats percent as division by 100', () => {
  assert.equal(enter('5', 'sign', '×', '2', '=').display, '-10');
  assert.equal(enter('5', '0', 'percent').display, '0.5');
  assert.equal(enter('0', 'sign').display, '0');
});

test('rejects division by zero and recovers on a new number', () => {
  const calculator = enter('8', '÷', '0', '=');
  assert.equal(calculator.display, 'Error');
  assert.equal(calculator.error, 'Cannot divide by zero');
  calculator.press('4');
  assert.equal(calculator.display, '4');
  assert.equal(calculator.error, '');
});

test('does not append more than 12 input digits or accept unsupported keys', () => {
  const calculator = enter(...'123456789012345');
  assert.equal(calculator.display, '123456789012');
  assert.throws(() => calculator.press('invalid'), /Unknown key/);
  const error = enter('1', '÷', '0', '=');
  assert.throws(() => error.press('invalid'), /Unknown key/);
});

test('allows a new entry after a large result', () => {
  const calculator = enter(...'999999999999', '×', ...'999999999999', '=');
  assert.match(calculator.display, /e\+/);
  calculator.press('sign');
  calculator.press('7');
  assert.equal(calculator.display, '7');
  calculator.press('backspace');
  assert.equal(calculator.display, '0');
});
