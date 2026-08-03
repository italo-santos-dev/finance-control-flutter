# Objetivo

Regulamentar a apresentação e leitura imersiva de notícias financeiras no sistema.

# Escopo

Seção de notícias na `HomePage` e página interna dedicada `NewsDetailPage`.

# Regras obrigatórias

1. **Fontes Oficiais**: Notícias devem ser consumidas em tempo real via BRAPI e feeds RSS oficiais (G1 Economia, InfoMoney, Valor Econômico).
2. **Leitura Interna Nível Bloomberg**: Clicar em qualquer card de notícia abre a `NewsDetailPage` dentro da aplicação com Hero Header, badge da categoria, tempo de leitura estimado, parágrafos formatados e lista de notícias relacionadas.
3. **Imagens Reais**: Imagens de notícias devem ser obtidas dinamicamente do XML/JSON da fonte. Nunca usar placeholders estáticos.

# Boas práticas

- Formatar o tempo de publicação (ex: *"há 15 minutos"* ou *"31 de Julho, 14:30"*).
- Disponibilizar ações de compartilhar link e salvar notícia.

# Componentes afetados

- `FinancialNewsService` (`lib/services/apis/api_news_service.dart`)
- `NewsDetailPage` (`lib/pages/news/news_detail_page.dart`)

# Exemplos de implementação

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => NewsDetailPage(newsItem: item),
  ),
);
```

# Critérios de aceite

- Leitura completa da matéria realizada 100% dentro do app sem popup ou redirecionamento externo.

# Referências internas

- [ux-navigation.skill.md](file:///.agents/skills/ux/ux-navigation.skill.md)
- [architecture-data-policy.skill.md](file:///.agents/skills/architecture/architecture-data-policy.skill.md)
