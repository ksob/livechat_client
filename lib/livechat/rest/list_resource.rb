#This file is based on code from https://github.com/twilio/twilio-ruby
#
#Copyright (c) 2010 Andrew Benton.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

module LiveChat
  module REST
    class ListResource
      include Utils

      def initialize(path, client)
        @path, @client = path, client
        resource_name = self.class.name.split('::')[-1]
        @instance_class = LiveChat::REST.const_get resource_name.chop
        @instance_id_key = 'id'
      end

      def inspect # :nodoc:
        "<#{self.class} @path=#{@path}>"
      end

      ##
      # Grab a list of this kind of resource and return it as an array. The
      # array includes a special attribute named +total+ which will return the
      # total number of items in the list on LiveChat's server. This may differ
      # from the +size+ and +length+ attributes of the returned array since
      # by default LiveChat will only return 50 resources, and the maximum number
      # of resources you can request is 1000.
      #
      # The optional +params+ hash allows you to filter the list returned. The
      # filters for each list resource type are defined by LiveChat.
      def list(params={}, full_path=false)
        raise "Can't get a resource list without a REST Client" unless @client
        response = @client.get @path, params, full_path
        resources = @list_key ? response[@list_key]: response
        path = full_path ? @path.split('.')[0] : @path
        resource_list = resources.map do |resource|
          @instance_class.new "#{path}/#{resource[@instance_id_key]}", @client,
            resource
        end
        # set the +total+ and +next_page+ properties on the array
        #client, list_class = @client, self.class
        #resource_list.instance_eval do
          #eigenclass = class << self; self; end
          #eigenclass.send :define_method, :total, &lambda {response['total']}
          #eigenclass.send :define_method, :next_page, &lambda {
          #  if response['next_page_uri']
          #    list_class.new(response['next_page_uri'], client).list({}, true)
          #  else
          #    []
          #  end
          #}
        #end
        resource_list
      end

      def new_customer(license_id, client_id)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/customer/token"
        response = @client.post @path, {
                      "license_id": license_id,
                      "grant_type": "agent_token",
                      "client_id": client_id,
                      "response_type": "token"
                    }
        return response
        
      end

      def new_customer_cookie(license_id, client_id, redirect_uri)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/customer/token"
        response = @client.post @path, {
                      "license_id": license_id.to_i,
                      "grant_type": "cookie",
                      "client_id": client_id,
                      "response_type": "token",
                      "redirect_uri": redirect_uri
                    }
        return response
      end

      def list_customers
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/agent/action/list_customers"
        response = @client.post @path, {}
        return response
      end

      def start_chat(organization_id, message_text)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/customer/action/start_chat?organization_id=#{organization_id}"
        response = @client.post @path, {
          chat: {
                  thread: {
                    events: [
                      {
                        type: "message",
                        text: message_text
                      }
                    ]
                  }
                }
        }
                
        return response
      end

      def resume_chat(organization_id, chat_id)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/customer/action/resume_chat?organization_id=#{organization_id}"
        response = @client.post @path, {
          chat: {
                  id: chat_id
                }
        }
                
        return response
      end


      def send_msg(organization_id, chat_id, message_text)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/customer/action/send_event?organization_id=#{organization_id}"
        response = @client.post @path, 
            { 
                "chat_id": chat_id,
                "event": {
                   "type": "message",
                   "text": message_text,
                   "recipients": "all"
                }
            }

        return response
      end

      def list_customer_chats(organization_id)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/customer/action/list_chats?organization_id=#{organization_id}"
        response = @client.post @path, {
        }
                
        return response
      end

      def add_user_to_chat(license_id, chat_id, customer_id)
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/agent/action/add_user_to_chat?license_id=#{license_id}"
        response = @client.post @path, 
                  {
                    "chat_id": chat_id,
                    "user_id": customer_id,
                    "user_type": "customer",
                    "visibility": "all",
                    "require_active_thread": false
                  }

        return response
      end

      def create_customer
        raise "Can't get a resource list without a REST Client" unless @client
        @path = "/v3.4/agent/action/create_customer"
        response = @client.post @path, 
                  {
                    "name": "Test Customer #{rand(9999999)}",
                    "email": "c#{rand(9999999)}@example.com",
                    "session_fields": [{
                    "custom_key": "custom_value"
                    }, {
                      "another_custom_key": "another_custom_value"
                    }]
                  }

        return response
      end

      ##
      # Ask LiveChat for the total number of items in the list.
      # Calling this method makes an HTTP GET request to <tt>@path</tt> with a
      # page size parameter of 1 to minimize data over the wire while still
      # obtaining the total. Don't use this if you are planning to
      # call #list anyway, since the array returned from #list will have a
      # +total+ attribute as well.
      #def total
      #  raise "Can't get a resource total without a REST Client" unless @client
      #  @client.get(@path, :page_size => 1)['total']
      #end

      ##
      # Return an empty instance resource object with the proper path. Note that
      # this will never raise a LiveChat::REST::RequestError on 404 since no HTTP
      # request is made. The HTTP request is made when attempting to access an
      # attribute of the returned instance resource object, such as
      # its #date_created or #voice_url attributes.
      def get(id)
        @instance_class.new "#{@path}/#{id}", @client
      end
      alias :find :get # for the ActiveRecord lovers

      ##
      # Return a newly created resource. Some +params+ may be required. Consult
      # the LiveChat REST API documentation related to the kind of resource you
      # are attempting to create for details. Calling this method makes an HTTP
      # POST request to <tt>@path</tt> with the given params
      def create(params={})
        raise "Can't create a resource without a REST Client" unless @client
        yield params if block_given?
        response = @client.post @path, params
        @instance_class.new "#{@path}/#{response[@instance_id_key]}", @client, response
      end

      def each
        list.each { |result| yield result }
      end
    end
  end
end
