import React from 'react';
import {Button, Checkbox, Container, Grid, Header, Icon, Image, Message} from 'semantic-ui-react';
import Keycloak from 'keycloak-js';

class App extends React.Component {

    state = {
        keycloak: null,
        authenticated: false,
        expired: false,
        backendData: ' ',
        showJwt: false,
        respectRoles: false,
        token: null,
        roles: []
    }

    componentDidMount = () => {
        const keycloak = new Keycloak("/keycloak.json");
        keycloak.init({}).then((authenticated) => {
            this.setState({keycloak: keycloak, authenticated: authenticated});
        }).catch((error) => {
            console.info("Catch error: " + error);
        });
        keycloak.onAuthSuccess = () => {
            console.info("Login successful for user ID = " + keycloak.subject);
            this.decodeJWT(keycloak.token);
        }
        keycloak.onAuthError = (errorData) => {
            console.info("Login failed: " + errorData);
        }
        keycloak.onAuthLogout = () => {
            this.setState({authenticated: false, expired: false});
            console.info("Logout successful");
        }
        keycloak.onTokenExpired = () => {
            console.info("Token expired for user ID = " + keycloak.subject);
            this.setState({expired: true});
        }
        keycloak.onAuthRefreshSuccess = () => {
            console.info("Token refreshed for user ID = " + keycloak.subject);
            this.decodeJWT(keycloak.token);
            this.setState({expired: false});
        }
        keycloak.onAuthRefreshError = () => {
            console.info("Token refresh failed");
        }
        keycloak.onReady = (authenticated) => {
            console.info("Keycloak client is Ready: authenticated=" + authenticated);
        }
    }

    decodeJWT = (token) => {
        const base64UrlToken = token.split('.')[1];
        const base64Token = base64UrlToken.replace('-', '+').replace('_', '/');
        const parsedToken = JSON.parse(window.atob(base64Token));
        this.setState({token: parsedToken, roles: parsedToken.groups});
    }

    fetchUserBackendData = () => {
        fetch('http://localhost:8080/secure/message/user', {headers: {'Authorization': ' Bearer ' + this.state.keycloak.token}})
            .then(response => response.text())
            .then(text => this.setState({backendData: text}));
    }

    fetchAdminBackendData = () => {
        fetch('http://localhost:8080/secure/message/admin', {headers: {'Authorization': ' Bearer ' + this.state.keycloak.token}})
            .then(response => response.text())
            .then(text => this.setState({backendData: text}));
    }

    clearBackendData = () => {
        this.setState({backendData: ' '});
    }

    handleShowJwt = (e, {checked}) => {
        this.setState({showJwt: checked});
    }

    handleRespectRoles = (e, {checked}) => {
        this.setState({respectRoles: checked});
    }

    login = () => {
        this.state.keycloak.login();
    }

    logout = () => {
        this.setState({authenticated: false, expired: false});
        this.state.keycloak.logout();
        console.info("Logout successful");
    }

    refresh = () => {
        this.state.keycloak.updateToken(0).then(function (refreshed) {
        }).catch((error) => {
            console.info("Catch error: " + error);
        });
    }

    render() {
        return (
            <Container>
                <br/>
                <Grid centered>
                    <Grid.Row>
                        <Grid.Column width={3}>
                            <Image src='ok-logo.png' size='small' wrapped/>
                        </Grid.Column>
                        <Grid.Column width={8}>
                            <Header as='h2' icon textAlign='center'>
                                Secure MicroProfile with JWT-Token
                                <Header.Subheader>A simple prototype with MicroProfile / Jakarta EE service, React
                                    web-application and Keycloak
                                </Header.Subheader>
                            </Header>
                        </Grid.Column>
                        <Grid.Column width={3}>
                            <Grid.Row style={{ height: '100%' }}>
                                <Grid.Column style={{ height: '50%', display: 'flex', alignItems: 'center'  }}>
                                {(() => {
                                    if (this.state.authenticated) {
                                        return (
                                            <Button onClick={this.logout}>Logout</Button>
                                        )
                                    } else {
                                        return (
                                            <Button onClick={this.login}>Login</Button>
                                        )
                                    }
                                })()}
                                    <Button onClick={this.refresh} disabled={!this.state.expired}>Refresh</Button>
                                </Grid.Column>
                                <Grid.Column style={{ height: '50%', display: 'flex', alignItems: 'center' }}>
                                    <Checkbox checked={this.state.respectRoles} label='Respect Roles' onChange={this.handleRespectRoles} toggle/>
                                </Grid.Column>
                            </Grid.Row>
                        </Grid.Column>
                    </Grid.Row>
                </Grid>

                <Grid centered columns={2}>
                    <Grid.Column>
                        {(() => {
                            if (this.state.authenticated && !this.state.expired) {
                                return (
                                    <Message positive icon='check circle outline' header='You are currently logged in'
                                         content='Try to access the REST API and get the secured message.'/>
                                )
                            } else if (this.state.authenticated && this.state.expired) {
                                return (
                                    <Message warning icon>
                                        <Icon name='clock outline'/>
                                        <Message.Content>
                                            <Message.Header>Your login is currently expired</Message.Header>
                                            Logout and Login in again to get redirected to Keycloak.
                                        </Message.Content>
                                    </Message>
                                )
                            } else {
                                return (
                                    <Message negative icon>
                                        <Icon name='times circle outline'/>
                                        <Message.Content>
                                            <Message.Header>You are currently not logged in</Message.Header>
                                            Login in to get redirected to Keycloak.
                                        </Message.Content>
                                    </Message>
                                )
                            }
                        })()}
                    </Grid.Column>
                </Grid>

                <Grid centered columns={2}>
                    <Grid.Column textAlign='center'>
                        <Header as='h2'>Access MicroProfile REST API</Header>
                        <Button onClick={this.fetchUserBackendData}
                                disabled={!this.state.authenticated || this.state.expired || (this.state.respectRoles && !this.state.roles.includes('USER'))}>Access as USER
                        </Button>
                        <Button onClick={this.fetchAdminBackendData}
                                disabled={!this.state.authenticated || this.state.expired || (this.state.respectRoles && !this.state.roles.includes('ADMIN'))}>Access as ADMIN
                        </Button>
                        <Button onClick={this.clearBackendData}
                                disabled={!this.state.authenticated || this.state.backendData === ' '}>Clear
                        </Button>
                        <Message>
                            <pre>{this.state.backendData}</pre>
                        </Message>
                        <Checkbox checked={this.state.showJwt} label='Show JWT' onChange={this.handleShowJwt} toggle/>
                    </Grid.Column>
                </Grid>

                <Grid centered>
                    <Grid.Row>
                        <Grid.Column width={3}/>
                        <Grid.Column width={8}>
                            {this.state.showJwt ?
                                <Message size='mini'>
                                    <Message.Header>The decoded JWT token</Message.Header>
                                    <Message.Content>
                                        <pre>
                                            {this.state.keycloak && this.state.keycloak.token ? JSON.stringify(this.state.token, null, 4) : 'n.A.'}
                                        </pre>
                                    </Message.Content>
                                </Message> :
                                <Message hidden/>}
                        </Grid.Column>
                        <Grid.Column width={3}/>
                    </Grid.Row>
                </Grid>

            </Container>

        );
    }

}

export default App;
