# Objetivo

Garantir adaptabilidade responsiva fluida entre dispositivos Mobile, Tablet e Web Desktop.

# Escopo

Breakpoints de tela, alteração de layouts de 1 para 2 colunas e redimensionamento dinâmico.

# Regras obrigatórias

1. **Breakpoint de Tela Larga**: Utilizar `MediaQuery.of(context).size.width > 900` para alternar entre visão Stacked (Mobile) e Wide (Desktop).
2. **Navegação Adaptável**: Em telas grandes, organizar os cards em grides horizontais lado a lado (`flex: 7` e `flex: 4`).
3. **Scroll Fluido**: Preservar a experiência de toque (*bouncing scroll*) no Mobile e barra de rolagem limpa no Web.

# Boas práticas

- Testar interfaces em resoluções de 360px, 768px, 1084px e 1920px.

# Componentes afetados

- `ActiveDetailsPage`
- `HomePage`

# Exemplos de implementação

```dart
bool isWide = MediaQuery.of(context).size.width > 900;
return isWide ? _buildWideLayout() : _buildStackedLayout();
```

# Critérios de aceite

- Nenhuma sobreposição de componentes ao redimensionar a janela do navegador.

# Referências internas

- [ui-layout.skill.md](file:///.agents/skills/ui/ui-layout.skill.md)
