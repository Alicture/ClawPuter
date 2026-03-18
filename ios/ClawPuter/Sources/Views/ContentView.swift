import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel.shared
    @State private var showingNotificationSheet = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Pet Animation
            GeometryReader { geometry in
                ZStack {
                    // Full screen pet view
                    PetView(viewModel: viewModel)
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    // Connection status overlay at top
                    VStack {
                        HStack {
                            Circle()
                                .fill(viewModel.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)

                            Text(viewModel.isConnected ? "Connected: \(viewModel.connectedIP ?? "Unknown")" : "Waiting for device...")
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(radius: 2)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }
            }
            .tabItem {
                Label("Pet", systemImage: "hare.fill")
            }
            .tag(0)

            // Tab 2: Chat Messages
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Chat")
                        .font(.headline)
                    Spacer()
                    if viewModel.isConnected {
                        Button(action: {
                            viewModel.clearMessages()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                ChatView(viewModel: viewModel)
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(1)
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { viewModel.triggerHappy() }) {
                        Label("Happy", systemImage: "face.smiling")
                    }
                    Button(action: { viewModel.triggerSleep() }) {
                        Label("Sleep", systemImage: "moon.fill")
                    }
                    Divider()
                    Button(action: { showingNotificationSheet = true }) {
                        Label("Send Notification", systemImage: "bell.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNotificationSheet) {
            NotificationSheet(viewModel: viewModel, isPresented: $showingNotificationSheet)
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}

struct NotificationSheet: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Details")) {
                    TextField("App Name", text: $viewModel.notifyApp)
                    TextField("Title", text: $viewModel.notifyTitle)
                    TextField("Body", text: $viewModel.notifyBody)
                }

                Section {
                    Button("Send Notification") {
                        viewModel.sendNotification()
                        isPresented = false
                    }
                    .disabled(viewModel.notifyApp.isEmpty || viewModel.notifyTitle.isEmpty || viewModel.notifyBody.isEmpty)
                }
            }
            .navigationTitle("Send Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
