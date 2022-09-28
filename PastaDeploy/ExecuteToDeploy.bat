@ECHO "Dando Push"
call sfdx force:source:push --json --loglevel fatal

PAUSE
ECHO "Quando setar seu permission set, clique qualquer botão"

@ECHO "Iniciando Carga..."
timeout /t 5

@ECHO "Escritorio"
call sfdx force:data:bulk:upsert -s SalesOffice__c -f ./EscritorioVenda.csv -i Codigo__c -w 2
@ECHO "Equipe"
call sfdx force:data:bulk:upsert -s SalesTeam__c -f ./EquipeVenda.csv -i ExternalId__c -w 2
@ECHO "Atividade"
call sfdx force:data:bulk:upsert -s ActivitySector__c -f ./SetorAtividade.csv -i Codigo__c -w 2
@ECHO "Organizacao"
call sfdx force:data:bulk:upsert -s SalesOrg__c -f ./OrgVenda.csv -i SalesOrganizationCode__c -w 2
@ECHO "Empresa"
call sfdx force:data:bulk:upsert -s Company__c -f ./Empresa.csv -i ExternalId__c -w 2
@ECHO "CONTA"
call sfdx force:data:bulk:upsert -s Account -f ./Conta.csv -i ExternalId__c -w 2
@ECHO "Grupo de Produto"
call sfdx force:data:bulk:upsert -s ProductGroup__c -f ./GrupoProduto.csv -i ExternalId__c -w 2
@ECHO "Safra"
call sfdx force:data:bulk:upsert -s Safra__c -f ./Safra.csv -i Code__c -w 2
@ECHO "Cultura"
call sfdx force:data:bulk:upsert -s Cultura__c -f ./Cultura.csv -i Codigo__c -w 2
@ECHO "Condicao de pagamento"
call sfdx force:data:bulk:upsert -s CondicaoPagamento__c -f ./CondicaoPagamento.csv -i Code__c -w 2
@ECHO "Condicao de venda"
call sfdx force:data:bulk:upsert -s SalesCondition__c -f ./CondicaoVenda.csv -i ExternalId__c -w 2
@ECHO "Produto"
call sfdx force:data:bulk:upsert -s Product2 -f ./Produto.csv -i ProductCode__c -w 2
@ECHO "OrgV"
call sfdx force:data:bulk:upsert -s OrgVProduct__c -f ./OrgV.csv -i OrgVExternal__c -w 2
@ECHO "Lista de Preco"
call sfdx force:data:bulk:upsert -s JurosDescontoAntecipao__c -f ./Precos.csv -i ExternalId__c -w 2


PAUSE
ECHO "Carga Finalizada... aperte qualquer botão"
CLS


