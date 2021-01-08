require 'uri'
require 'net/https'
require 'net/http'
require "open-uri"
require 'pry'
require 'json'


class NessusCommunication
    attr_reader :token
    attr_reader :url
    def initialize(user, password,url)
        if not defined?@url
            @url = url
        end
        post = { "username" => user, "password" => password }
        body = nessus_request("#{@url}/session",post,'post')
        body = JSON.parse(body)
        @token = body['token']
    end

    def nessus_request(uri, data,method) 
        url = URI.parse(uri) 
        begin
            if not defined?@https
                @https = Net::HTTP.new( url.host, url.port )
                @https.use_ssl = true
                @https.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
        rescue 
            puts "Erro ao tentar fazer o request"
            exit
        end

        if method.upcase == "POST"
            request = Net::HTTP::Post.new( url.path , {"X-Cookie" => "token=#{@token}"}) 
            request.set_form_data( data )
            response = @https.request( request )
        else
            if data != ""
                url.query = URI.encode_www_form(data)
            end
            request = Net::HTTP::Get.new( url.path )
            response = @https.get(url.request_uri)
        end
        return response.body
    end

    def scan_list_all()
        token = { "token" => @token } 
        body = nessus_request("#{@url}/scans",token, "get")
        body = JSON.parse(body)
        return body
    end

    def scan_copy_by_id(id,name,folder)
        if name == -1 && folder == -1
            token = { "token" => @token , "name" => name} 
        elsif folder == nil || folder == "" || folder == -1
            token = { "token" => @token , "name" => name} 
        else
            token = { "token" => @token , "name" => name,"folder_id" => folder} 
        end
        url = "#{@url}/scans/#{id}/copy"
        body = nessus_request(url,token,"post")
    end
    def scan_by_id(id,type)
        token = {"token" => @token}
        url = "#{@url}/scans/#{id}/#{type}"
        body = nessus_request(url,token,"post")
    end
end

session = NessusCommunication.new('nessus','nessus','https://localhost:8834')
binding.pry