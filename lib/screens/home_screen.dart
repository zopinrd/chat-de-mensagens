// Exemplo de tela Home para navegação por abas
// (Conteúdo real da HomeScreen permanece, mas pode ser adaptado para navegação por abas)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/loading_spinner.dart';
import 'login_screen.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../providers/friend_provider.dart';

/// Tela principal do app após login/autenticação.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  UserModel? _user;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Busca as informações do usuário autenticado.
  Future<void> _loadUserData() async {
    print('Iniciando carregamento do usuário...');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('isAuthenticated: ${authProvider.isAuthenticated}');
      print('userEmail: ${authProvider.userEmail}');
      print('userId: ${authProvider.userId}');
      _user = UserModel(
        id: authProvider.userId ?? '',
        email: authProvider.userEmail ?? '',
        name: 'Usuário',
        createdAt: DateTime.now(),
        avatarUrl: '',
        fcmToken: '',
      );
      print('Usuário carregado: $_user');
    } catch (e) {
      _error = 'Erro ao carregar dados do usuário.';
      print('Erro: $_error');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('Carregamento finalizado. isLoading: $_isLoading, error: $_error');
    }
  }

  /// Executa o logout e navega para a tela de login.
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSearch(UserProvider userProvider) async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      await userProvider.searchUsers(_searchController.text.trim());
      if (userProvider.errorMessage.isNotEmpty) {
        _showSnackbar(userProvider.errorMessage);
      }
    }
  }

  Future<void> _onAddFriend(FriendProvider friendProvider, String friendId) async {
    if (friendId.trim().isEmpty) {
      _showSnackbar('ID do amigo não pode ser vazio');
      return;
    }
    await friendProvider.addFriend(friendId);
    if (friendProvider.errorMessage.isNotEmpty) {
      _showSnackbar(friendProvider.errorMessage);
    } else {
      _showSnackbar('Solicitação de amizade enviada!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final friendProvider = Provider.of<FriendProvider>(context);
    // Scaffold com AppBar e Drawer para navegação
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do Drawer com informações do usuário
            UserAccountsDrawerHeader(
              accountName: Text(_user?.name ?? ''),
              accountEmail: Text(_user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _user?.avatarUrl.isNotEmpty == true
                    ? NetworkImage(_user!.avatarUrl)
                    : null,
                child: _user?.avatarUrl.isEmpty == true
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            // Opções de navegação futuras
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                // TODO: Navegar para tela de perfil
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                // TODO: Navegar para tela de configurações
              },
            ),
            const Divider(),
            // Botão de logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
      body: _isLoading
          // Exibe spinner enquanto carrega dados
          ? const Center(child: LoadingSpinner())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: _user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(_user!.avatarUrl)
                            : null,
                        child: _user?.avatarUrl.isEmpty == true
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_user?.name ?? '', style: Theme.of(context).textTheme.titleLarge),
                          Text(_user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Busca de usuários SEMPRE visível
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomInputField(
                          labelText: 'Buscar usuário',
                          controller: _searchController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Digite um termo para buscar';
                            }
                            return null;
                          },
                          prefixIcon: Icons.search,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Buscar',
                          isLoading: userProvider.isLoading,
                          onPressed: () => _onSearch(userProvider),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (userProvider.isLoading)
                    const LoadingSpinner(message: 'Buscando usuários...')
                  else if (userProvider.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        userProvider.errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (userProvider.users.isEmpty && _searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum usuário encontrado',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (userProvider.users.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = userProvider.users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl!))
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: friendProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: LoadingSpinner(size: 20),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.person_add),
                                    tooltip: 'Adicionar amigo',
                                    onPressed: () => _onAddFriend(friendProvider, user.id),
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
