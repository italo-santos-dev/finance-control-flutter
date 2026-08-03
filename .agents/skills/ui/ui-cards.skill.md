# Objetivo

Estipular os padrões visuais e estruturais dos cartões de informação e cards financeiros da plataforma.

# Escopo

Cards de cotação de mercado, cards de notícias, cards de indicadores, cartões de gráficos e seções da Home.

# Regras obrigatórias

1. **Estrutura Visual**: Fundo `AppColors.cardDark`, bordas suavizadas com `BorderRadius.circular(12)` ou `14`, e contorno `Border.all(color: AppColors.borderDark)`.
2. **Padding Interno Padronizado**: Usar `EdgeInsets.all(16)` ou `20` para manter respiro adequado dos dados.
3. **Interatividade**: Cards clicáveis devem acionar navegação nativa interna mantendo o estado da tela anterior.

# Boas práticas

- Agrupar conteúdos com hierarquia clara (Ticker/Título ➔ Subtítulo ➔ Valor Principal ➔ Variação).
- Não truncar desnecessariamente informações críticas de preços ou indicadores.

# Componentes afetados

- `HomePage` cards
- `NewsDetailPage` cards
- `ActiveDetailsPage` cards

# Exemplos de implementação

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppColors.cardDark,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.borderDark),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [ ... ],
  ),
);
```

# Critérios de aceite

- Todos os cards do aplicativo possuem cantos arredondados e borda translúcida refinada.
- Espaçamento interno consistente de no mínimo 16px.

# Referências internas

- [ui-design-system.skill.md](file:///.agents/skills/ui/ui-design-system.skill.md)
