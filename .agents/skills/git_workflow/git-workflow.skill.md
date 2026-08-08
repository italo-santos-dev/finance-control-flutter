---
name: git-workflow
description: Padronização e diretrizes obrigatórias de versionamento Git, revisão de diff, validação antes do commit, prevenção de vazamento de credenciais e push seguro com Conventional Commits.
---

# Git Workflow Skill

## Objetivo

Padronizar o processo de versionamento do projeto, garantindo que commits e pushes sejam realizados de forma segura, rastreável, organizada e profissional.

Esta Skill deve ser consultada sempre que uma tarefa envolver:

- commit;
- push;
- branch;
- merge;
- pull request;
- organização do histórico;
- preparação de alterações para entrega.

---

# Regra principal

Sempre que uma implementação for concluída e o usuário solicitar commit e/ou push, o agente deve:

1. analisar as alterações realizadas;
2. verificar o estado do Git (`git status`);
3. revisar os arquivos modificados;
4. verificar possíveis arquivos indevidos;
5. validar a implementação (lint / build / testes);
6. criar um commit descritivo e semântico;
7. realizar o push para o branch correto;
8. confirmar o resultado da operação.

Nunca realizar um commit ou push sem antes verificar o estado atual do repositório.

---

# Consulta obrigatória das Skills

Antes de realizar o commit, consultar as Skills relacionadas ao trabalho executado.

Exemplo:

Se a alteração foi relacionada à UI:
- `ui-design-system.skill.md`
- `ui-components.skill.md`
- `ux-navigation.skill.md`

Se foi relacionada a dados:
- `architecture-data-policy.skill.md`
- `architecture-api.skill.md`
- `real-data-policy.skill.md`

Se foi relacionada à implementação de uma funcionalidade:
- consultar as Skills específicas daquela funcionalidade.

A implementação deve estar em total conformidade com as Skills antes de ser versionada.

---

# Antes do commit

Executar uma revisão completa do repositório.

Verificar:

- `git status`;
- arquivos modificados;
- arquivos adicionados;
- arquivos removidos;
- arquivos não rastreados;
- diferenças do código;
- alterações inesperadas;
- arquivos temporários;
- arquivos de build;
- credenciais;
- tokens;
- chaves de API;
- arquivos `.env`;
- arquivos gerados automaticamente.

Nunca incluir informações sensíveis no commit.

---

# Revisão do diff

Antes de criar o commit, analisar o diff completo (`git diff` ou `git diff --staged`).

Verificar se:

- a alteração corresponde à tarefa solicitada;
- não existem alterações acidentais;
- não existem códigos de debug;
- não existem `print`, `console.log` ou logs temporários desnecessários;
- não existem comentários temporários ou TODOs esquecidos;
- não existem mocks indevidos ou violações da política de dados reais;
- não existem dados hardcoded;
- não existem arquivos temporários;
- não existem alterações não relacionadas à tarefa.

Se forem encontradas alterações não relacionadas, não incluí-las no commit sem necessidade.

---

# Validação

Antes do commit, executar as validações disponíveis no projeto:

- `flutter analyze` / `dart analyze`;
- lint;
- formatter;
- testes unitários / testes de integração;
- build check;
- type checking;
- análise estática.

Utilizar os comandos definidos pelo próprio projeto. Não inventar comandos ou ferramentas que não existam no projeto.

---

# Falha na validação

Se uma validação falhar:

1. identificar a causa;
2. corrigir o problema quando estiver relacionado à implementação;
3. executar novamente a validação;
4. somente criar o commit após obter um resultado aceitável (0 erros).

Nunca esconder uma falha para conseguir realizar o commit.

Se o erro não puder ser corrigido, informar claramente o problema antes de prosseguir.

---

# Política de commits

Cada commit deve representar uma alteração lógica e coerente.

Evitar commits gigantes contendo alterações não relacionadas.

### Conventional Commits

Utilizar Conventional Commits sempre que possível no formato:

```text
<type>(<scope>): <description>
```

**Tipos permitidos:**
- `feat` — nova funcionalidade
- `fix` — correção de bug
- `refactor` — refatoração sem mudança funcional
- `perf` — melhoria de performance
- `style` — alterações visuais/formatação
- `test` — testes
- `docs` — documentação
- `build` — alterações de build/dependências
- `ci` — CI/CD
- `chore` — manutenção

**Exemplos:**
```text
feat(asset): implement dynamic asset details page
fix(search): reset results after returning from asset details
perf(market): optimize global market data loading
style(dashboard): improve financial card layout
docs(skills): add git workflow guidelines
```

---

# Qualidade da mensagem

A mensagem do commit deve explicar claramente:
- o que foi alterado;
- qual parte do sistema foi afetada.

**Evitar mensagens genéricas como:**
- `update`
- `changes`
- `fix`
- `test`
- `alterações`
- `commit`
- `final`
- `new version`

A mensagem deve ser compreensível mesmo sem visualizar o diff.

### Commit detalhado

Quando solicitado pelo usuário a realizar um commit detalhado, utilizar:

```text
<type>(<scope>): <short description>

- alteração importante 1
- alteração importante 2
- alteração importante 3
- melhoria de performance
- correções de comportamento
```

Não transformar o commit em uma descrição excessivamente longa do projeto. Descrever apenas as alterações realmente realizadas.

---

# Staging

Não executar automaticamente `git add .` sem antes verificar o que será incluído.

Preferir adicionar explicitamente os arquivos relacionados à tarefa quando houver risco de incluir arquivos indevidos.

Antes do commit, verificar novamente:
```bash
git diff --staged
```

---

# Push

Após o commit:
- verificar branch atual (`git branch --show-current`);
- verificar se existe upstream configurado;
- confirmar que o commit está correto;
- realizar o push para o repositório remoto apropriado.

Preferir:
```bash
git push
```
quando o upstream já estiver configurado.

Caso seja necessário definir o upstream:
```bash
git push -u origin <branch>
```

Nunca fazer push forçado (`--force`) sem autorização explícita do usuário.

---

# Proteção contra operações destrutivas

É terminantemente proibido executar automaticamente:
- `git reset --hard`
- `git clean -fd`
- `git push --force`
- `git push --force-with-lease`
- `git checkout .`
- `git restore .`

Esses comandos podem destruir alterações do usuário.

Somente utilizá-los quando houver autorização explícita e quando a operação estiver claramente justificada.

---

# Branch

Antes do push, verificar:
```bash
git branch --show-current
```

Nunca assumir que o branch correto é `main` ou `master` sem checar. Utilizar o branch atualmente destinado à tarefa, respeitando a estratégia existente no projeto.

---

# Conflitos

Se o push for rejeitado por divergência com o remoto:
1. não sobrescrever o histórico;
2. analisar o estado do repositório;
3. verificar se existem commits remotos;
4. sincronizar utilizando a estratégia adotada pelo projeto;
5. resolver conflitos;
6. executar novamente as validações;
7. somente então realizar o push.

Nunca utilizar `--force` para simplesmente contornar um conflito.

---

# Segurança

Nunca realizar commit contendo:
- API keys;
- tokens;
- senhas;
- credenciais;
- certificados privados;
- arquivos `.env` com informações sensíveis;
- secrets;
- credenciais de serviços.

Antes do commit, procurar alterações suspeitas relacionadas a credenciais.

---

# Verificação pós-push

Depois do push, confirmar:
- branch;
- commit enviado;
- hash do commit;
- remote;
- resultado do push.

Exemplo de confirmação:
```text
Commit criado:
feat(asset): implement dynamic asset details page

Commit: abc1234
Branch: master
Remote: origin

Push realizado com sucesso.
```

Não afirmar que o push foi realizado sem verificar o resultado real do comando.

---

# Regra de integridade

Nunca alterar o histórico Git apenas para deixar o histórico "bonito" sem necessidade.

Não fazer:
- squash arbitrário;
- rebase desnecessário;
- amend de commits existentes;
- reset;
- force push.

Sem uma justificativa clara e autorização quando houver risco de afetar trabalho existente.

---

# Fluxo obrigatório

Sempre seguir este fluxo inquebrável:

```
Implementação
      ↓
Consultar Skills
      ↓
Revisar código
      ↓
git status
      ↓
Revisar diff
      ↓
Validar projeto (analyze / lint / tests)
      ↓
Verificar arquivos sensíveis
      ↓
git add
      ↓
git diff --staged
      ↓
git commit
      ↓
Verificar commit
      ↓
Verificar branch
      ↓
git push
      ↓
Confirmar push
```

---

# Critérios de aceite

Uma tarefa de Git somente estará concluída quando:

- [ ] As Skills relevantes foram consultadas.
- [ ] O código foi revisado.
- [ ] O diff foi analisado.
- [ ] Não existem arquivos indevidos no commit.
- [ ] Não existem credenciais ou secrets.
- [ ] As validações disponíveis foram executadas com sucesso.
- [ ] O commit possui mensagem clara e profissional.
- [ ] O commit segue Conventional Commits.
- [ ] O branch correto foi verificado.
- [ ] O push foi realizado com sucesso.
- [ ] O resultado do push foi confirmado.
