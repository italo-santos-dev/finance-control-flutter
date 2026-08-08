---
name: real_data_policy
description: Política Global e Obrigatória de Dados Reais - Proibido utilizar dados mockados, hardcoded, simulados ou fictícios em qualquer funcionalidade do projeto.
---

# Política Global de Dados Reais

## Objetivo

Toda a aplicação deve operar exclusivamente com dados reais, obtidos dinamicamente a partir das fontes oficiais integradas ao sistema.

É terminantemente proibido utilizar dados mockados, hardcoded, simulados, fictícios ou placeholders para representar informações reais em qualquer ambiente de produção ou desenvolvimento integrado.

Esta é uma regra obrigatória do projeto, sem exceções.

---

## Regra Fundamental

Sempre que um componente, tela, serviço ou funcionalidade precisar exibir informações ao usuário, os dados devem ser obtidos dinamicamente.

A ordem obrigatória de obtenção é:

1. **APIs oficiais integradas ao projeto.**
2. **Camadas de Web Scraping implementadas pelo sistema** (quando a API não disponibilizar a informação).
3. **Cache gerado a partir dessas fontes.**

Nunca criar dados manualmente para preencher a interface.

---

## É Proibido

Nunca utilizar:

- Dados mockados
- Mock Services
- Fake APIs
- Fixtures para alimentar a interface
- JSONs estáticos
- Arrays hardcoded
- Objetos criados manualmente
- Empresas fixas
- Notícias fictícias
- Rankings simulados
- Preços inventados
- Indicadores calculados sobre dados inexistentes
- Dividendos fictícios
- Valores aleatórios
- Imagens de exemplo
- Placeholders representando dados reais
- Qualquer informação criada apenas para "deixar a interface bonita"

Se o dado não existir, a interface deve informar que ele está indisponível.

---

## Fontes Oficiais

Toda informação deve ser proveniente de:

- APIs oficiais do projeto;
- APIs públicas homologadas;
- Web Scraping implementado pelo sistema (quando permitido e necessário);
- Banco de dados da aplicação;
- Cache gerado exclusivamente a partir dessas fontes.

---

## Hierarquia das Fontes

Sempre seguir esta prioridade:

```
API Oficial
      ↓
Web Scraping
      ↓
Cache
      ↓
Estado de indisponibilidade
```

Nunca inverter essa ordem.

---

## Tratamento de Indisponibilidade

Caso uma informação não possa ser obtida:

1. Tentar novamente conforme a política de retry;
2. Consultar o cache válido;
3. Exibir estado de carregamento durante a busca;
4. Exibir mensagem de indisponibilidade caso nenhuma fonte retorne dados.

**Nunca substituir a ausência de dados por informações fictícias.**

---

## Estados da Interface

A UI deve possuir apenas estes estados:

- **Loading**
- **Success**
- **Empty**
- **Error**
- **Offline**

Não existe estado "Mock".

---

## Arquitetura Obrigatória

Toda obtenção de dados deve passar por uma camada de serviços ou repositórios.

A interface deve apenas consumir os dados já processados.

A UI não pode:
- Criar dados;
- Modificar respostas das APIs para inventar informações;
- Preencher listas manualmente;
- Construir rankings artificialmente.

---

## Componentes Afetados

Esta regra aplica-se a:

- Dashboard
- Home
- Carteira
- Ativos
- Notícias
- Mercados Globais
- Rankings
- Indicadores
- Gráficos
- Proventos
- Agenda Econômica
- Watchlist
- Perfil
- Configurações
- Relatórios
- Qualquer funcionalidade futura

---

## Desenvolvimento

Durante o desenvolvimento:
- Não criar mocks temporários na interface;
- Não adicionar valores apenas para visualizar componentes;
- Não manter código de teste em produção;
- Remover imediatamente qualquer mock utilizado em testes locais antes do merge.

---

## Revisão de Código

Todo Pull Request deve validar obrigatoriamente:

- Existe algum dado hardcoded?
- Existe algum array estático representando dados reais?
- Existe algum JSON criado manualmente?
- Existe algum ranking fixo?
- Existe alguma empresa fixa?
- Existe alguma notícia fictícia?
- Existe algum preço inventado?
- Existe algum gráfico alimentado por dados simulados?

Se qualquer resposta for **SIM**, o Pull Request deve ser rejeitado até que a implementação utilize dados reais.

---

## Critérios de Aceite

Uma funcionalidade somente poderá ser considerada concluída quando:

1. Todos os dados forem obtidos dinamicamente.
2. Nenhum dado estiver hardcoded.
3. Nenhum mock estiver presente na interface.
4. Toda informação puder ser rastreada até sua fonte de origem.
5. A interface exibir corretamente os estados de Loading, Empty, Error e Offline.
6. APIs forem utilizadas como fonte principal.
7. Web Scraping for utilizado apenas quando a API não fornecer os dados necessários.
8. O cache armazenar apenas dados provenientes dessas fontes.

---

## Regra Permanente

Esta política possui **prioridade máxima** sobre qualquer outra instrução do projeto.

Qualquer implementação que utilize dados mockados, hardcoded ou simulados deve ser considerada incorreta e refeita.

Antes de concluir qualquer tarefa, o agente deve verificar automaticamente se todos os dados exibidos são provenientes de APIs, Web Scraping ou cache derivado dessas fontes. Caso contrário, a implementação não deve ser considerada finalizada.
