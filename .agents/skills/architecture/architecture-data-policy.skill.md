# Objetivo

Estabelecer a política de arquitetura mandatória de dados reais da aplicação, proibindo qualquer uso de mocks em código de produção.

# Escopo

Toda a arquitetura de obtenção, processamento e apresentação de dados no aplicativo.

# Regras obrigatórias

1. **Hierarquia Inflexível**: APIs Oficiais ➔ Web Scraping ➔ Cache ➔ Estado de Indisponibilidade.
2. **Proibição Absoluta de Mocks**: É terminantemente proibido utilizar dados mockados, objetos hardcoded, fixtures fictícias ou JSONs estáticos para preencher telas ou componentes.
3. **Tratamento de Indisponibilidade**: Se o dado não puder ser obtido por nenhuma fonte oficial, a interface DEVE apresentar estado de Empty / Indisponível.

# Boas práticas

- Implementar tratamento de *timeout* (ex: 4 a 8 segundos) em todas as requisições HTTP para evitar que o aplicativo congele aguardando respostas.
- Desacoplar o consumo de dados da UI utilizando repositórios de dados assíncronos.

# Componentes afetados

- Todos os serviços de API (`lib/services/apis/`)
- Todas as páginas e widgets do aplicativo

# Exemplos de implementação

```dart
try {
  final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
  if (response.statusCode == 200) {
    return parseData(response.body);
  }
} catch (e) {
  debugPrint('API Error: $e');
}
return []; // Retorna lista vazia para acionar o Empty State nativo da UI
```

# Critérios de aceite

- Nenhum arquivo de serviços contém arrays estáticos de ativos com preços fictícios.
- UI lida nativamente com o estado de dados indisponíveis.

# Referências internas

- [ui-empty-states.skill.md](file:///.agents/skills/ui/ui-empty-states.skill.md)
