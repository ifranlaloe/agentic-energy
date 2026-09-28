import { Calculator, isKey, type Key } from './calculator';

function getElement<T extends Element>(selector: string, type: { new (): T }): T {
  const element = document.querySelector(selector);
  if (!(element instanceof type)) {
    throw new Error(`Missing calculator element: ${selector}`);
  }
  return element;
}

const display = getElement('#display', HTMLOutputElement);
const expression = getElement('#expression', HTMLParagraphElement);
const message = getElement('#message', HTMLParagraphElement);
const keypad = getElement('#keypad', HTMLDivElement);
const calculator = new Calculator();
const hint = message.textContent ?? '';
function render(): void {
  display.textContent = calculator.display;
  expression.textContent = calculator.expression || '\u00a0';
  message.textContent = calculator.error || hint;
  message.classList.toggle('message--error', Boolean(calculator.error));
}

function press(key: Key): void {
  calculator.press(key);
  render();
}

keypad.addEventListener('click', (event) => {
  const target = event.target;
  if (!(target instanceof HTMLButtonElement)) return;
  const key = target.dataset.key;
  if (key && isKey(key)) press(key);
});

document.addEventListener('keydown', (event) => {
  if (event.altKey || event.ctrlKey || event.metaKey) return;
  const input = event.key;
  const key = input === 'Enter' ? '='
    : input === 'Escape' || input === 'Delete' ? 'clear'
    : input === 'Backspace' ? 'backspace'
    : input === '*' || input.toLowerCase() === 'x' ? '×'
    : input === '/' ? '÷'
    : input === '-' ? '−'
    : input;
  if (!isKey(key)) return;
  event.preventDefault();
  press(key);
});
