//
//  PostDetailView.swift
//  FITstagram
//
//  Created by Guest User on 11/20/23.
//

import SwiftUI

struct PostDetailView: View {
    
    // MARK: - Internal properties
    
    let post: Post
    var onCommentsTapped: (() -> Void)?
    
    // MARK: - Private properties
    
    // To re-enforce the local nature of @State properties, Apple recommends you mark them as private
    @State private var isBookmarked = false
    @State private var comments: [Comment] = []
    @State private var text = ""
    @State private var isAlertPresented = false
    @State private var commentToBeDeleted: Comment?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading) {
                headerView
                    .padding(.horizontal)
                if post.photos.count == 1 {
                    if let photoURL = post.photos.first {
                        RemoteImage(url: photoURL)
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: UIScreen.main.bounds.size.width,
                                height: 300
                            )
                            .clipped()
                    }
                } else if post.photos.count > 1 {
                    TabView {
                        ForEach(post.photos, id: \.self) { photoURL in
                            RemoteImage(url: photoURL)
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: UIScreen.main.bounds.size.width,
                                    height: 300
                                )
                                .clipped()
                        }
                    }
                    .frame(
                        width: UIScreen.main.bounds.size.width,
                        height: 300
                    )
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
                footerView
                    .padding(.top, 2)
                    .padding(.horizontal)
                Spacer()
            }
            .padding()
            .tint(.pink) // Tint color is applied to all nested precedents
        }
        .task {
            await fetchComments()
        }
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        NavigationLink(value: post.author) {
            Text(post.author.username)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.myForeground)
                .padding()
                .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var footerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            buttonsHorizontalView
                .frame(height: 24)

            footerTextsView
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
    }
    
    private var buttonsHorizontalView: some View {
        HStack(spacing: 16) {
            imageButton(iconName: "heart") {
                print($0 + " tapped!")
            }

            imageButton(iconName: "paperplane") {
                print($0 + " tapped!")
            }

            Spacer()

            imageButton(
                iconName: isBookmarked ? "bookmark.fill" : "bookmark"
            ) { _ in
                isBookmarked.toggle()
            }
        }
    }

    private var footerTextsView: some View {
            VStack(alignment: .leading, spacing: 7) {
                NavigationLink(value: post.likes) {
                    Text(String(post.likes) + " To se mi líbí!")
                        .fontWeight(.semibold)
                        .foregroundStyle(.myForeground)
                }
                
                Text(post.author.username)
                    .fontWeight(.semibold)
                +
                Text(" " + post.text)
                commentsListView
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .safeAreaInset(edge: .bottom) {
                        HStack(spacing: 8) {
                            TextField("Add some text!", text: $text)
                                .autocorrectionDisabled()
                            
                            Button {
                                comments.append(
                                    Comment(
                                        id: String(Int.random(in: 1..<10000))+String(NSDate().hashValue),
                                        author: .userMockMe,
                                        likes: [],
                                        text: text
                                    )
                                )
                                text = ""
                            } label: {
                                Image(systemName: "paperplane")
                            }
                        }
                        .tint(.pink)
                        .padding()
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray, style: .init(lineWidth: 2))
                        }
                        .padding()
                    }
                    .alert(
                        "Chceš to opravdu smazat?",
                        isPresented: $isAlertPresented,
                        actions: {
                            Button(role: .cancel) {
                                commentToBeDeleted = nil
                            } label: {
                                Text("Zavřít")
                            }
                            
                            Button(role: .destructive) {
                                // Removes all the elements that satisfy the given predicate
                                comments.removeAll(where: {
                                    $0 == commentToBeDeleted
                                })
                            } label: {
                                Text("Smazat")
                            }
                        }
                    ) {
                        Text("Dojde k nenávratnému smazání komentáře")
                    }
        }
    }
    
    private var commentsListView: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Comments")
                .fontWeight(.bold)
            ForEach(comments) { comment in
                HStack {
                    Text(comment.author.username)
                        .fontWeight(.semibold)
                    
                    if comment.author == .userMockMe {
                        Button {
                            commentToBeDeleted = comment
                            isAlertPresented = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.pink)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(" " + comment.text)
            }
        }
    }
    
    /// Returns button with a wrapped image for given system icon name
    /// - Parameters:
    ///   - name: Given system icon name
    ///   - action: Action which should be performed on tap
    ///
    /// - Note: `@escaping` - Tells the Swift compiler that we know
    /// the closure leaves the scope it was passed to, and that we're okay with that
    private func imageButton(
        iconName name: String,
        action: @escaping (String) -> Void
    ) -> some View {
        Button {
            action(name)
        } label: {
            Image(systemName: name)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
    
    private func fetchComments() async {
        var request = URLRequest(url: URL(string: "https://fitstagram.ackee.cz/api/feed/" + String(post.id) + "/comments")!)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let comments = try! JSONDecoder().decode([Comment].self, from: data)
            
            self.comments = comments
        }
        catch {
            print("[ERROR] Comments fetch error.")
        }
    }
}

#Preview {
    PostDetailView(post: .postMock)
}
