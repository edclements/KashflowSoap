class KashflowSoap

  def initialize username, password, options
    raise "missing username/password" unless username and password
    namespaces = {"xmlns:kas" => "KashFlow"}
    @client = Savon.client do |globals|
      globals.wsdl "https://securedwebapp.com/api/service.asmx?wsdl"
      globals.convert_request_keys_to :none
      globals.ssl_version :TLSv1
      globals.ssl_ca_cert_file options[:ssl_ca_cert_file] if options[:ssl_ca_cert_file]
      globals.env_namespace :soapenv
      globals.namespace_identifier :kas
      globals.namespaces namespaces
      globals.log false
    end
    @auth = {UserName: username, Password: password}
  end

  def call m, message = nil
    if message
      body = {message: message.merge(@auth)}
      response = @client.call(m, body)
    else
      response = @client.call(m, {message: @auth})
    end
    response = response.body["#{m}_response".to_sym]
    result = response["#{m}_result".to_sym]
    status = response[:status]
    result if status != "NO"
  end

  def insert_customer customer
    result = call :insert_customer, {custr: customer}
    if result
      customer[:CustomerID] = result
      customer
    end
  end

  def get_customer_by_id id
    call :get_customer_by_id, {CustomerID: id.to_s}
  end

  def insert_invoice invoice
    result = call :insert_invoice, {Inv: invoice}
    if result
      invoice[:InvoiceNumber] = result
      invoice
    end
  end

  def get_invoice id
    invoice = call :get_invoice, {InvoiceNumber: id.to_s}
    invoice if invoice[:invoice_dbid] != "0"
  end

  def get_inv_pay_methods
    result = call :get_inv_pay_methods
    result[:payment_method] if result
  end

  def get_bank_account
    result = call :get_bank_accounts
    result[:bank_account] if result
  end

  def insert_invoice_payment payment
    call :insert_invoice_payment, {InvoicePayment: payment}
  end

  def insert_invoice_line invoice_id, line
    call :insert_invoice_line, {InvoiceID: invoice_id, InvLine: line}
  end

  def method_missing m, message = nil
    call m, message
  end

end
