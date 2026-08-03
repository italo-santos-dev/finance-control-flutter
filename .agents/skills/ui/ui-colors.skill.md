# Objetivo

Definir a paleta de cores oficial, tokens de significado financeiro e regras de contraste do sistema.

# Escopo

Definição e aplicação de cores primárias, secundárias, neutras, indicadoras de lucro/prejuízo e estados no Flutter.

# Regras obrigatórias

1. **Cores de Mercado**: Verde (`AppColors.emeraldGreen` - `#00E676` ou `#10B981`) para lucros/altas; Vermelho (`AppColors.redLoss` - `#FF5252` ou `#EF4444`) para perdas/baixas.
2. **Superfícies Escuras**: Background principal (`#0F1117`), Cards (`#181B24`), Header (`#13151D`), Bordas (`#262B38`).
3. **Proibido Cores Genéricas**: Nunca usar `Colors.green` ou `Colors.red` puros do Flutter sem o tratamento da paleta do aplicativo.

# Boas práticas

- Utilizar variação de opacidade (`withValues(alpha: ...)`) para fundos de badges e destaques secundários.
- Garantir legibilidade de texto branco e cinza suave sobre fundos escuros.

# Componentes afetados

- `lib/core/app_colors.dart`
- Gráficos, Badges, Botões e Cards

# Exemplos de implementação

```dart
Text(
  isPositive ? '+2.45%' : '-1.80%',
  style: TextStyle(
    color: isPositive ? AppColors.emeraldGreen : AppColors.redLoss,
    fontWeight: FontWeight.bold,
  ),
);
```

# Critérios de aceite

- Todas as variações percentuais utilizam exclusivamente `AppColors.emeraldGreen` ou `AppColors.redLoss`.
- Ausência de cores genéricas padrão do navegador/framework.

# Referências internas

- [ui-design-system.skill.md](file:///.agents/skills/ui/ui-design-system.skill.md)
