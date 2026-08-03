# Objetivo

Padronizar os componentes de botão e ações da aplicação, incluindo estados de hover, toque e estilo minimalista.

# Escopo

Todos os botões primários (CTAs), botões secundários, botões de ícone e botões pílula ("Ver todos" / filtros).

# Regras obrigatórias

1. **Botões "Ver Todos"**: Utilizar obrigatoriamente o componente `ModernSeeAllButton` (altura 30px, borda arredondada 16px e animação suave ao passar o mouse).
2. **Botões CTAs Primários**: Utilizar `ModernCtaButton` com tom azul accent e texto em negrito.
3. **Micro-Animação**: Todos os botões interativos devem apresentar feedback visual (mudança de opacidade ou brilho) ao toque ou hover.

# Boas práticas

- Manter a área clicável mínima de 44x44px no mobile para acessibilidade de toque.
- Manter o texto dos botões sucinto e no infinitivo ("Ver DRE Completa", "Filtrar").

# Componentes afetados

- `lib/widgets/buttons/modern_see_all_button.dart`
- `lib/widgets/buttons/modern_cta_button.dart`

# Exemplos de implementação

```dart
ModernSeeAllButton(
  onTap: () => navigateToWalletPage(),
);
```

# Critérios de aceite

- Nenhum botão possui aparência genérica do sistema.
- Todos os botões reutilizam widgets de `lib/widgets/buttons/`.

# Referências internas

- [ui-design-system.skill.md](file:///.agents/skills/ui/ui-design-system.skill.md)
