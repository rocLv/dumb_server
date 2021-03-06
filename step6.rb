require 'socket'

# STEP 6: Read POST requests, too.

def log_connection(request_headers, request_body, response)
    if request_body
        request = request_headers + "\n\n" + request_body
    else
        request = request_headers
    end

    print <<-EOF.gsub(/^ */, "")
        ==================================
        ====== NEW REQUEST INCOMING ======
        ==================================

        ------ REQUEST -------------------
    EOF
    print request
    print <<-EOF.gsub(/^ */, "")
        \n----------------------------------

        ------ RESPONSE ------------------
    EOF
    print response
    print "\n----------------------------------\n\n"
end

MAIN_PAGE = <<-EOF.gsub(/^ {4}/, "")
    <!doctype html>
    <html lang="en">
        <head>
            <title>Saucy</title>
        </head>
        <body>
            <form action="/sauce" method="POST">
                <input name="sauce_type" value="sriracha" />
                <input type="submit" />
            </form>
        </body>
    </html>
EOF

EMPTY_LINE = /^\s*$/

server = TCPServer.new('127.0.0.1', 9090)

while connection = server.accept()

    content_length = nil

    lines = []
    while line = connection.gets and line !~ EMPTY_LINE
        if line.start_with?("Content-Length")
            content_length = line.split(": ")[-1].to_i
        end
        lines << line.chomp
    end

    if content_length
        # Without the Content-Length header, we have no way of knowing when to
        # stop reading. The HEADERS are always plain text, so we were able to
        # just look for an empty line, but the request BODY could be anything:
        # Form data, JSON, an image, an MP3!
        request_body = connection.readpartial(content_length)
    else
        request_body = nil
    end

    method, path, protocol = lines[0].split(" ")
    request_headers = lines.join("\n")

    response_code = '200 OK'

    response_body = case method
    when "GET"
        case path
        when '/favicon.ico'
            response_code = '404 Not Found'
            'Sorry! No favicon, pal.'
        else
            MAIN_PAGE.strip()
        end
    when "POST"
        case path
        when '/sauce'
            "OK! Have some #{request_body.split('=').last}."
        end
    end

    response_headers = <<-EOF.gsub(/^ */, "")
        HTTP/1.1 #{response_code}\r
        Content-Type: text/html\r
    EOF

    response = response_headers + "\r\n" + response_body

    connection.write(response)
    connection.close()

    log_connection(request_headers, request_body, response)

end
