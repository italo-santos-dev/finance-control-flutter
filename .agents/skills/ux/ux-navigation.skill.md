# Objetivo

Definir os padrões de navegação interna imersiva da aplicação, eliminando redirecionamentos externos indesejados.

# Escopo

Navegação entre telas (Home, Detalhes da Notícia, Detalhes do Ativo, Carteira).

# Regras obrigatórias

1. **Navegação Interna Imersiva**: Ao clicar em qualquer card de notícia ou card de ativo, o usuário DEVE ser direcionado para uma tela/rota interna dedicada (`NewsDetailPage` / `ActiveDetailsPage`).
2. **Proibido Abrir Navegador Externo**: É proibido abrir abas de navegador externo ou popups sem consentimento explícito.
3. **Preservação de Estado**: A navegação deve utilizar `Navigator.push` nativo em Flutter com transição suave, permitindo o retorno direto ao estado anterior sem perda de scroll ou busca.

# Boas práticas

- Manter o botão de retorno `<-` (voltar) visível no canto superior esquerdo da barra de navegação.
- Manter o estado do filtro ativo ao voltar de uma sub-tela.

# Componentes afetados

- `HomePage`
- `NewsDetailPage`
- `ActiveDetailsPage`

# Exemplos de implementação

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NewsDetailPage(news: item),
  ),
);
```

# Critérios de aceite

- O usuário navega 100% dentro da aplicação sem sair para o browser.
- O botão voltar retorna exatamente para a posição da Home onde o card foi clicado.

# Referências internas

- [ui-buttons.skill.md](file:///.agents/skills/ui/ui-buttons.skill.md)
