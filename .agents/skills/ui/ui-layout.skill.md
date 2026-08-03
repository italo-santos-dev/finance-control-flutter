# Objetivo

Definir as diretrizes de layout, alinhamento, grid de colunas e containers principais da interface Web e Mobile.

# Escopo

Estrutura de telas, `Scaffold`, `Column`, `Row`, `Expanded`, `Flexible` e áreas responsivas.

# Regras obrigatórias

1. **Largura Máxima em Web**: Containers centrais em telas Web/Desktop devem ser limitados com `BoxConstraints(maxWidth: 1200)`.
2. **Sem Estouro de Pixels**: Utilizar `SingleChildScrollView` ou `Expanded` em listas para impedir erros de `RenderFlex overflowed`.
3. **Cálculo Dinâmico**: Proibido valores estáticos mágicos para altura (ex: `height: 487.3`). Usar flexibilidade estrutural.

# Boas práticas

- Alinhar títulos de seções com ícones e margens consistentes (8px, 12px, 16px, 20px).

# Componentes afetados

- `HomePage`
- `ActiveDetailsPage`
- `NewsDetailPage`

# Exemplos de implementação

```dart
Center(
  child: Container(
    constraints: const BoxConstraints(maxWidth: 1200),
    child: Column( ... ),
  ),
)
```

# Critérios de aceite

- Layout se ajusta a telas de 320px até 4K sem estourar limites.

# Referências internas

- [ux-responsive.skill.md](file:///.agents/skills/ux/ux-responsive.skill.md)
