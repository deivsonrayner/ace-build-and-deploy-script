# ace-build-and-deploy-scritps

Os scritps foram criados como referência para a implementação de fluxos de integração e implantação continua de Aplicações e Configurações do ACE utilizando os recursos do Operator conforme documentado em: https://www.ibm.com/support/knowledgecenter/SSTTDS_11.0.0/com.ibm.ace.icp.doc/certc_install_appconnectcomponents.html

A estrutura deste repositório representa uma estrutura de um projeto template. Espera-se que esta estrutura seja responsável pelo o build e deployment de um único componente de micro-flow implementado atravês de um BAR. 

O conteúdo deste repositório inclue dois tipos de script:

A) Um script responsável por criar uma Build Config que será utilizado para gerar imagens do ACE customizadas que incorporam o BAR da aplicação. O script setup-buildconfig.sh é responsável por todos os passos de configuração e atualização das configurações de build. A documentação do script pode ser acessada utilizando "--help".

B) Um script responsável por realizar o deployment e a criação de todos os Secrets, Configurations e o IntegrationServer necessários para o funcionamento do fluxo utilizando o Operator do ACE. O script deploy-project.sh é responsável por esta operação sua documentação pode ser acessada utilizando "--help".

Ambos scripts suportam a execução com parâmetro "--dry-run" permitindo revisar como as operações serão realizadas, qual estrutura de YAML será criado, etc.

Este projeto é uma iniciativa para automatização do ACE utilizando soluções como Jenkins e Tekton com enfase em uma esteira baseada nos conceitos de GitOps, toda colaboração e sugestão é bem vinda! 


