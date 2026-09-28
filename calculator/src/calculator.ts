export type Operator = '+' | '−' | '×' | '÷';
export type Key = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' |
  '.' | Operator | '=' | 'clear' | 'sign' | 'percent' | 'backspace';

const MAX_DIGITS = 12;
const validKeys: ReadonlySet<string> = new Set<Key>([
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.',
  '+', '−', '×', '÷', '=', 'clear', 'sign', 'percent', 'backspace',
]);

export function isKey(value: string): value is Key {
  return validKeys.has(value);
}

function format(value: number): string {
  if (!Number.isFinite(value)) {
    throw new RangeError('Result is too large');
  }
  return value === 0 ? '0' : Number(value.toPrecision(MAX_DIGITS)).toString();
}

function calculate(left: number, right: number, operator: Operator): number {
  switch (operator) {
    case '+': return left + right;
    case '−': return left - right;
    case '×': return left * right;
    case '÷':
      if (right === 0) {
        throw new RangeError('Cannot divide by zero');
      }
      return left / right;
  }
}

export class Calculator {
  display = '0';
  expression = '';
  error = '';
  private operand: number | null = null;
  private operator: Operator | null = null;
  private waitingForNumber = false;

  press(key: Key): void {
    if (!isKey(key)) {
      throw new RangeError(`Unknown key: ${key}`);
    }
    if (key === 'clear') {
      this.clear();
      return;
    }
    if (this.error) {
      if (key === 'backspace' || /^[0-9.]$/.test(key)) {
        this.clear();
      } else {
        return;
      }
    }

    if (/^[0-9]$/.test(key)) {
      this.digit(key);
    } else if (key === '.') {
      this.decimal();
    } else if (key === 'backspace') {
      this.backspace();
    } else if (key === 'sign') {
      this.transform((value) => -value);
    } else if (key === 'percent') {
      this.transform((value) => value / 100);
    } else if (key === '+' || key === '−' || key === '×' || key === '÷') {
      this.chooseOperator(key);
    } else if (key === '=') {
      this.equals();
    }
  }

  private clear(): void {
    this.display = '0';
    this.expression = '';
    this.error = '';
    this.operand = null;
    this.operator = null;
    this.waitingForNumber = false;
  }

  private digit(value: string): void {
    if (this.waitingForNumber) {
      this.display = value;
      this.waitingForNumber = false;
      if (!this.operator) this.expression = '';
    } else if (this.display.includes('e')) {
      this.display = value;
    } else if (this.display === '0') {
      this.display = value;
    } else if (this.display.replace(/[^0-9]/g, '').length < MAX_DIGITS) {
      this.display += value;
    }
  }

  private decimal(): void {
    if (this.waitingForNumber) {
      this.display = '0.';
      this.waitingForNumber = false;
      if (!this.operator) this.expression = '';
    } else if (!this.display.includes('.') && !this.display.includes('e')) {
      this.display += '.';
    }
  }

  private backspace(): void {
    if (this.waitingForNumber && this.operator) return;
    this.waitingForNumber = false;
    if (!this.operator) this.expression = '';
    if (this.display.includes('e')) {
      this.display = '0';
      return;
    }
    this.display = this.display.length < 2 ? '0' : this.display.slice(0, -1);
    if (this.display === '-' || this.display === '') this.display = '0';
  }

  private transform(action: (value: number) => number): void {
    if (this.waitingForNumber && this.operator) return;
    try {
      this.display = format(action(Number(this.display)));
      this.waitingForNumber = false;
      if (!this.operator) this.expression = '';
    } catch (error) {
      if (!(error instanceof RangeError)) throw error;
      this.fail(error.message);
    }
  }

  private chooseOperator(next: Operator): void {
    if (this.operator && !this.waitingForNumber) {
      if (!this.evaluate(this.operator)) return;
    }
    this.operand = Number(this.display);
    this.operator = next;
    this.expression = `${this.display} ${next}`;
    this.waitingForNumber = true;
  }

  private equals(): void {
    if (!this.operator || this.waitingForNumber) return;
    if (this.operand === null) throw new Error('Missing first operand');
    this.expression = `${format(this.operand)} ${this.operator} ${this.display} =`;
    if (!this.evaluate(this.operator)) return;
    this.operand = null;
    this.operator = null;
    this.waitingForNumber = true;
  }

  private evaluate(operator: Operator): boolean {
    if (this.operand === null) throw new Error('Missing first operand');
    try {
      this.display = format(calculate(this.operand, Number(this.display), operator));
      return true;
    } catch (error) {
      if (!(error instanceof RangeError)) throw error;
      this.fail(error.message);
      return false;
    }
  }

  private fail(message: string): void {
    this.clear();
    this.display = 'Error';
    this.error = message;
  }
}
