import SwiftUI

struct ContentView: View {
    @StateObject private var router = SearchRouter.shared
    @State private var searchText = ""
    @State private var showPhotoFinder = false

    private var results: [Fruit] {
        FruitCatalog.search(searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search a fruit", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Label("Search with Siri", systemImage: "waveform")
                } footer: {
                    Text("Try: “Search for mango in Fruit Finder.”")
                }

                Section {
                    Button {
                        showPhotoFinder = true
                    } label: {
                        Label("Identify Fruit from Photo", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section(searchText.isEmpty ? "Fruits" : "Search Results") {
                    if results.isEmpty {
                        ContentUnavailableView(
                            "Fruit Not Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try Apple, Banana, Mango, Orange, Strawberry, Watermelon, Pineapple, or Kiwi.")
                        )
                    } else {
                        ForEach(results) { fruit in
                            FruitRow(fruit: fruit)
                        }
                    }
                }
            }
            .navigationTitle("Fruit Finder")
            .sheet(isPresented: $showPhotoFinder) {
                NavigationStack {
                    FruitPhotoView()
                }
            }
            .onAppear {
                searchText = router.query
            }
            .onChange(of: router.query) { _, newQuery in
                searchText = newQuery
            }
        }
    }
}

private struct FruitRow: View {
    let fruit: Fruit

    var body: some View {
        HStack(spacing: 14) {
            Text(fruit.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(fruit.name)
                    .font(.headline)

                Text(fruit.details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}
