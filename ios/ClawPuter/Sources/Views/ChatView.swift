import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: AppViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.chatMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    if let lastMessage = viewModel.chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input area
            HStack(spacing: 8) {
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }

                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(viewModel.inputText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 2) {
                Text(message.role == "user" ? "You" : "AI")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(message.text)
                    .font(.body)
                    .padding(10)
                    .background(message.role == "user" ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .cornerRadius(16)
            }

            if message.role != "user" {
                Spacer(minLength: 40)
            }
        }
    }
}
