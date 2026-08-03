# Objetivo

Padronizar a criação e reutilização de componentes visuais modulares da interface.

# Escopo

Todos os componentes Flutter reutilizáveis em `lib/widgets/`.

# Regras obrigatórias

1. **Responsabilidade Única**: Cada componente deve ter foco único e ser auto-contido.
2. **Parâmetros Declarativos**: Propriedades devem ser passadas via construtor com tipos estritos e imutabilidade (`const`).
3. **Estilização por Tokens**: É proibido utilizar estilos ad-hoc dentro de componentes. Usar `AppColors`.

# Boas práticas

- Manter componentes pequenos (menos de 150 linhas por arquivo).
- Extrair widgets reutilizáveis para `lib/widgets/` agrupados por domínio (`buttons/`, `home/`, `adverts/`).

# Componentes afetados

- `lib/widgets/`

# Exemplos de implementação

```dart
class CustomCardWidget extends StatelessWidget {
  final Widget child;
  const CustomCardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: child,
    );
  }
}
```

# Critérios de aceite

- Componentes reutilizáveis sem duplicação de estilos.

# Referências internas

- [ui-design-system.skill.md](file:///.agents/skills/ui/ui-design-system.skill.md)
