# Regras do Projeto (AGENTS.md)

## Política Global e Obrigatória de Dados Reais (Proibido Mockar Dados)

- Toda a aplicação deve operar exclusivamente com dados reais, obtidos dinamicamente a partir das fontes oficiais integradas ao sistema.
- É terminantemente proibido utilizar dados mockados, hardcoded, simulados, fictícios ou placeholders para representar informações reais em qualquer ambiente.
- Ordem de obtenção obrigatória: **APIs Oficiais** ➔ **Web Scraping** ➔ **Cache**.
- Estados permitidos na UI: **Loading**, **Success**, **Empty**, **Error**, **Offline**. Não existe estado "Mock".
- Se uma informação não estiver disponível em nenhuma fonte oficial, a interface deve exibir explicitamente a indicação de indisponibilidade.
