---
name: ui_design_system
description: Diretrizes de UI Design System, tokens globais e tema Dark Mode.
---

# Objetivo

Estabelecer os princípios fundamentais, tokens e estrutura base do Design System da aplicação, garantindo consistência visual e experiência premium em todas as telas.

# Escopo

Aplica-se a todas as variáveis de estilo, temas (Dark/Light Mode), tokens visuais, paletas globais e estrutura base da interface Web e Mobile em Flutter.

# Regras obrigatórias

1. **Tema Dark Financeiro Primário**: O aplicativo deve utilizar Dark Mode refinado com paleta Tailored HSL (`AppColors.backgroundDark`, `AppColors.cardDark`, `AppColors.headerDark`).
2. **Uso de Tokens Globais**: É proibido utilizar valores de cores e espaçamentos *ad-hoc* no código. Sempre utilizar `AppColors` e tokens padronizados.
3. **Consistência Visual**: Todos os componentes devem herdar os raios de borda (`BorderRadius.circular(8)` ou `12`) e bordas translúcidas (`AppColors.borderDark`).

# Boas práticas

- Manter alto contraste para legibilidade dos dados financeiros.
- Utilizar superfícies translúcidas em camadas (*glassmorphism* sutil) para destacar cartões e áreas interativas.

# Componentes afetados

- `AppColors` (`lib/core/app_colors.dart`)
- `ThemeData` (`lib/main.dart`)

# Exemplos de implementação

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.cardDark,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.borderDark),
  ),
  child: const Padding(
    padding: EdgeInsets.all(16.0),
    child: Text('Exemplo'),
  ),
);
```
