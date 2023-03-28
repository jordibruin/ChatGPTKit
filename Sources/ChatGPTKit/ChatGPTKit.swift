import Foundation

public struct ChatGPTKit {
    // Initializer
    private var apiKey: String!
    public init(apiKey: String!) {
        self.apiKey = apiKey
    }
    
    // MARK: Completion Endpoint
    public func performCompletions(
        model: Model = .turbo,
        systemMessage: Message,
        messages: [Message] = [],
        temperature: Double = 1.0,
        topP: Double = 1.0,
        numberOfCompletions: Int = 1,
        presencePenalty: Double = 0,
        frequencePenalty: Double = 0
    ) async throws -> Result<Response, APIError> {
        
        
        var convertedMessages = [[String:Any]]()
        
        var tempMessages = messages
        print(messages.contentCount)
        
        while tempMessages.contentCount > 3700 {
            tempMessages = tempMessages.suffix(tempMessages.count - 1)
        }
        
        convertedMessages.append(systemMessage.convertToDict())
        for message in tempMessages {
            convertedMessages.append(message.convertToDict())
        }
        
        let parameters: [String: Any] = [
            "model": model.rawValue,
            "messages": convertedMessages,
            "temperature": temperature,
            "top_p": topP,
            "n": numberOfCompletions,
            "presence_penalty": presencePenalty,
            "frequency_penalty": frequencePenalty
        ]
        
        switch try await createRequest(with: URL(string: Constants.baseAPIURL), parameters: parameters) {
        case .success(let baseRequest):
            do {
                let (data, _) = try await URLSession.shared.data(for: baseRequest)
                print(String(data: data, encoding: .utf8)!)
                do {
                    let response = try JSONDecoder().decode(Response.self, from: data)
                    return .success(response)
                } catch {
                    // Try decoding as ResponseError type
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        return .failure(errorResponse.error)
                    } catch {
                        return .failure(
                            APIError(
                                message: error.localizedDescription,
                                error: error
                            )
                        )
                    }
                }
            } catch {
                return .failure(
                    APIError(
                        message: error.localizedDescription,
                        error: error
                    )
                )
            }
        case .failure(let error):
            return .failure(
                APIError(
                    message: error.localizedDescription,
                    error: error
                )
            )
        }
    }
    
    // MARK: PRIVATE
    private enum Constants {
        static let baseAPIURL = "https://api.openai.com/v1/chat/completions"
    }
    
    private func createRequest(with url: URL?, parameters: [String: Any]) async throws -> Result<URLRequest, APIError> {
        guard let apiURL = url else {
            return .failure(
                APIError(
                    message: "Call made to an invalid URL"
                )
            )
        }
        
        guard let key = apiKey else {
            return .failure(
                APIError(
                    message: "Call made to the OpenAI API using an invalid key"
                )
            )
        }
        
        do {
            let bodyData = try JSONSerialization.data(
                withJSONObject: parameters,
                options: []
            )
            
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = bodyData
            request.timeoutInterval = 90
            return .success(request)
        } catch {
            return .failure(
                APIError(
                    message: "Could not serialize the URL request"
                )
            )
        }
    }
}

extension Array where Element == Message {    
    var contentCount: Int { reduce(0, { $0 + $1.content.count })}
}
