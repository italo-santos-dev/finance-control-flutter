# Objetivo

Estabelecer os princípios fundamentais, tokens e estrutura base do Design System da aplicação, garantindo consistência visual e experiência premium em todas as telas.

# Escopo

Aplica-se a todas as variáveis de estilo, temas (Dark/Light Mode), tokens visuais, paletas globais e estrutura base da interface Web e Mobile em Flutter.

# Regras obrigatórias

1. **Tema Dark Financeiro Primário**: O aplicativo deve utilizar Dark Mode refinado com paleta Tailored HSL (`AppColors.backgroundDark`, `AppColors.cardDark`, `AppColors.headerDark`).
2. **Uso de Tokens Globais**: É proibido utilizar valores de cores e espaçamentos *ad-hoc* no código (ex: `Color(0xFF1E2230)`). Sempre utilizar `AppColors` e tokens padronizados.
3. **Consistência Visual**: Todos os componentes devem herdar os raios de borda (`BorderRadius.circular(8)` ou `12`) e bordas translúcidas (`AppColors.borderDark`).

# Boas práticas

- Manter alto contraste para legibilidade dos dados financeiros.
- Utilizar superfícies translúcidas em camadas (*glassmorphism* sutil) para destacar cartões e áreas interativas.
- Preservar consistência de marca com o logotipo e variações da cor azul accent (`AppColors.blueAccent`).

# Componentes afetados

- `AppColors` (`lib/core/app_colors.dart`)
- `ThemeData` (`lib/main.dart`)
- Todos os componentes visuais da aplicação

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
    child: Text('Card Consistente', style: TextStyle(color: AppColors.white)),
  ),
);
```

# Critérios de aceite

- 100% dos componentes utilizam tokens do `AppColors`.
- Nenhuma cor hardcoded avulsa no código de UI.
- O tema escuro atende aos padrões de contraste WCAG AA.

# Referências internas

- [ui-colors.skill.md](file:///.agents/skills/ui/ui-colors.skill.md)
- [ui-typography.skill.md](file:///.agents/skills/ui/ui-typography.skill.md)
