import subprocess
import os

class RefactoringProcess:
    option=""
    def __init__(self, option) -> None:
      self.option = option
    
    def execute_comment(self) -> None:
      if self.option == "1":
        self.__comment_custom_account()
        self.__comment_lookup()
        self.__comment_order_screen()
        self.__deploy_data()
      elif self.option == "2":
        self.__comment_custom_account()
        self.__comment_lookup()
        self.__comment_order_screen()
      elif self.option == "3":
        self.__deploy_data()
        
    def __comment_custom_account(self) -> None:

      file_name_CustomAccount = ".\\force-app\\main\\default\\classes\\CustomAccountLookupController.cls"
      file1 = open(file_name_CustomAccount, 'r+', encoding="utf8")
      lines = file1.readlines()
      indexInitial = 0
      indexFinal = 0
      for a in lines:
        if "if (profileName != 'Balcão') {" in a:
          indexInitial = lines.index(a)
        if "for(SObject s" in a:
          indexFinal = lines.index(a) - 2


      lines[indexInitial] = '/*' + lines[indexInitial]
      lines[indexFinal] =  lines[indexFinal] + '*/' + '          ' + "query = 'SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account WHERE (Name LIKE \\'' + String.escapeSingleQuotes(searchString.trim()) + '%\\' OR Name LIKE \\'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\\' OR CPF__c LIKE \\'' + String.escapeSingleQuotes(searchString.trim()) + '%\\' OR Company__c LIKE \\'' + String.escapeSingleQuotes(removeAccents(searchString.trim())) + '%\\' OR Company__c LIKE \\'' + String.escapeSingleQuotes(searchString.trim()) + '%\\') LIMIT 49999';"

      file1.seek(0)
      file1.truncate(0)
      file1.writelines(lines)

      file1.close()   

    def __comment_lookup(self) -> None:
      file_name_Lookup = ".\\force-app\\main\\default\\classes\\Lookup.cls"
      file1 = open(file_name_Lookup, 'r+', encoding="utf8")
      lines = file1.readlines()
      indexInitial = 0
      indexFinal = 0
      for a in lines:
        if "if (requestData.targetObject == 'User' && !clientTerritoriesScreen) {" in a:
          indexInitial = lines.index(a)
        if "query += ' AND BarterCondition__c =: barterSale';" in a:
          indexFinal = lines.index(a) +1


      lines[indexInitial] = '/*' + lines[indexInitial]
      lines[indexFinal] =  lines[indexFinal] + '*/' 

      file1.seek(0)
      file1.truncate(0)
      file1.writelines(lines)

      file1.close()

    def __comment_order_screen(self) -> None:
      file_name_OrderScreen = ".\\force-app\\main\\default\\classes\\OrderScreenController.cls"
      file1 = open(file_name_OrderScreen, 'r+', encoding="utf8")
      lines = file1.readlines()
      indexInitial = 0
      indexFinal = 0
      for a in lines:
        if "if (profileName != 'Balcão') {" in a:
          indexInitial = lines.index(a)
        if "for(Account account : accountList) accountListSerialize.add(new AccountSerialize(account));" in a:
          indexFinal = lines.index(a) - 2


      lines[indexInitial] = '/*' + lines[indexInitial]
      lines[indexFinal] =  lines[indexFinal] + '*/' + '          ' + "accountList = [SELECT Id, Name, CNPJ__c, CPF__c, ExternalId__c, Company__c, Phone, BillingCity, BillingState FROM Account];"

      indexSpecial = 0
      for a in lines:
        if "if (salesTeamTerritory != null && salesTeamTerritory.DeveloperName != null) {" in a:
          indexInitial = lines.index(a)
        if "for (Company__c salesTeamCompany : Database.query(proQuery.build())) {" in a:
          indexFinal = lines.index(a) -1
        if "if(isHeader)" in a:
          indexSpecial = lines.index(a) -1

      lines[indexInitial] = '/*' + lines[indexInitial]
      lines[indexFinal] =  lines[indexFinal] + '*/'
      lines[indexSpecial] =  '//' + lines[indexSpecial]
      file1.seek(0)
      file1.truncate(0)
      file1.writelines(lines)

      file1.close()

    def __deploy_data(self) -> None:
      subprocess.call(os.path.join(os.path.dirname(__file__), 'ExecuteToDeploy.bat'))

response = input('Escolha uma opção:\n 1: Comentar Classes e deploy dados\n 2: Apenas Comentar Classes\n 3: Apenas deploy de dados\n')

process = RefactoringProcess(response)
process.execute_comment()