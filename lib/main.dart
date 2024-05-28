import 'blog_row.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  runApp(const MyApp());
}

final HttpLink httpLink = HttpLink("https://api-us-west-2.hygraph.com/v2/clwltmfi5000008kyd034gjb3/master");
final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
  GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(),
  ),
);

const String query = """
query Content{
  posts{
    id
    title
    excerpt
    coverImage {
      url
    }
  }
}
""";

const String updatePostMutation = """
mutation {
  updatePost(
    where: { id: "ckadrcx4g00pw01525c5d2e56" }
    data: { author: "Elijah Asaolu" }
  ) {
    id
    name
    price
  }
}
""";

const String newPostSub = """
subscription newPost {
  post(where: {mutation_in: [CREATED]}) {
    node {
      id
      title
      content
      createdAt
    }
  }
}
""";


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'GraphQL Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text("Hygraph Blog"),
          ),
          body: Query(
            options: QueryOptions(
              document: gql(query),
              variables: const <String, dynamic>{"variableName": "value"},
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (result.data == null) {
                return const Center(
                  child: Text("No article found!"),
                );
              }
              final posts = result.data!['posts'];
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final title = post['title'];
                  final excerpt = post['excerpt'];
                  final coverImageURL = post['coverImage']['url'];
                  return BlogRow(
                    title: title,
                    excerpt: excerpt,
                    coverURL: coverImageURL,
                  );
                },
              );
            },
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Mutation(
                options: MutationOptions(document: gql(updatePostMutation)),
                builder: (runMutation, result) {
                  return FloatingActionButton(
                    onPressed: () {
                      runMutation({});
                      // Do something with result
                    },
                    child: const Icon(Icons.update),
                  );
                },
              ),
              const SizedBox(height: 10),
              Subscription(
                options: SubscriptionOptions(document: gql(newPostSub)),
                builder: (result) {
                  if (result.isLoading) {
                    return const FloatingActionButton(
                      onPressed: null,
                      child: Icon(Icons.sync),
                    );
                  }
                  if (result.data == null) {
                    return const FloatingActionButton(
                      onPressed: null,
                      child: Icon(Icons.error),
                    );
                  }
                  final newPostTitle = result.data!["post"]["node"]["title"];
                  return FloatingActionButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('New Post Created'),
                          content: Text(newPostTitle),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.notifications),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
