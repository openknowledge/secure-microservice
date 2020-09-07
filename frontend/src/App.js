import React from 'react';
import {Button, Checkbox, Grid, Header, Icon, Image, Message} from 'semantic-ui-react';
import Keycloak from 'keycloak-js';
import Container from "semantic-ui-react/dist/commonjs/elements/Container";
import Divider from "semantic-ui-react/dist/commonjs/elements/Divider";

class App extends React.Component {

    state = {
        keycloak: null,
        authenticated: false,
        expired: false,
        backendData: ' ',
        showJwt: false,
        respectRoles: true,
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
            <Container style={{border: '1px #006491 solid'}}>
                <Grid style={{margin: '0'}}>
                    <Grid.Row style={{backgroundColor: '#006491', borderBottom: '1px solid white'}}>
                        <Grid.Column width={4} style={{display: 'flex', alignItems: 'center'}}>
                            <Image src='ok-logo.png' size='small' wrapped style={{margin: 'auto', marginLeft: '0'}}/>
                        </Grid.Column>
                        <Grid.Column width={8} style={{display: 'flex', alignItems: 'center'}}>
                            <Header as='h2' icon textAlign='center' style={{margin: 'auto', color: 'lightgrey'}}>
                                Secure MicroProfile with JWT-Token
                                <Header.Subheader style={{color: 'lightgrey'}}>A simple prototype with MicroProfile /
                                    Jakarta
                                    EE service, React
                                    web-application and Keycloak
                                </Header.Subheader>
                            </Header>
                        </Grid.Column>
                        <Grid.Column width={4} style={{display: 'flex', alignItems: 'center'}}>
                            <Grid.Row style={{marginLeft: 'auto'}}>
                                <Grid.Column style={{height: '50%', display: 'flex', alignItems: 'center'}}>
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
                            </Grid.Row>
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#f8f8f9', paddingBottom: '0'}}>
                        <Grid.Column width={10} style={{display: 'flex', alignItems: 'center', marginLeft: 'auto'}}>
                            {(() => {
                                if (this.state.authenticated && !this.state.expired) {
                                    return (
                                        <Message positive icon='check circle outline'
                                                 header='You are currently logged in'
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
                        <Grid.Column width={3} style={{display: 'flex', alignItems: 'center'}}>
                            <Checkbox
                                style={{marginLeft: 'auto', marginRight: '14px', marginTop: '0', marginBottom: 'auto'}}
                                checked={this.state.respectRoles} label='Respect Roles'
                                onChange={this.handleRespectRoles} toggle/>
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#f8f8f9'}}>
                        <Grid.Column style={{display: 'flex', alignItems: 'center'}}>
                            <Divider horizontal style={{margin: '0'}}>
                                <Header as='h4'>Access MicroProfile REST API</Header>
                            </Divider>
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#f8f8f9', padding: '0'}}>
                        <Grid.Column style={{display: 'flex', alignItems: 'center'}}>
                            <Button style={{marginLeft: 'auto'}} onClick={this.fetchUserBackendData}
                                    disabled={!this.state.authenticated || this.state.expired || (this.state.respectRoles && !this.state.roles.includes('USER'))}>Access
                                as USER
                            </Button>
                            <Button onClick={this.fetchAdminBackendData}
                                    disabled={!this.state.authenticated || this.state.expired || (this.state.respectRoles && !this.state.roles.includes('ADMIN'))}>Access
                                as ADMIN
                            </Button>
                            <Button style={{marginRight: 'auto'}} onClick={this.clearBackendData}
                                    disabled={!this.state.authenticated || this.state.backendData === ' '}>Clear
                            </Button>
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#f8f8f9'}}>
                        <Grid.Column width={10} textAlign='center' style={{
                            display: 'flex',
                            alignItems: 'center',
                            marginLeft: 'auto',
                            marginRight: 'auto'
                        }}>
                            <Message style={{width: '100%', backgroundColor: 'white', boxShadow: '0 0 0 1px rgba(0,0,0,.6) inset,0 0 0 0 transparent'}}>
                                <pre style={{ color: 'rgba(0,0,0,.8)' }}>{this.state.backendData}</pre>
                            </Message>
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#f8f8f9', padding: '0'}}>
                        <Grid.Column style={{display: 'flex', alignItems: 'center'}}>
                            <Checkbox style={{marginLeft: 'auto', marginRight: 'auto'}} checked={this.state.showJwt}
                                      label='Show JWT' onChange={this.handleShowJwt}
                                      toggle/>
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#f8f8f9'}}>
                        <Grid.Column width={7} style={{marginLeft: 'auto', marginRight: 'auto'}}>
                            {(() => {
                                if (this.state.showJwt) {
                                    return (
                                        <Message size='mini' style={{ backgroundColor: 'white', boxShadow: '0 0 0 1px rgba(0,0,0,.6) inset,0 0 0 0 transparent', color: 'rgba(0,0,0,.8)' }}>
                                            <Message.Header>The decoded JWT token</Message.Header>
                                            <Message.Content>
                                                <pre style={{ color: 'rgba(0,0,0,.6)' }}>{this.state.keycloak && this.state.keycloak.token ? JSON.stringify(this.state.token, null, 4) : 'n.A.'}</pre>
                                            </Message.Content>
                                        </Message>
                                    );
                                }
                            })()}
                        </Grid.Column>
                    </Grid.Row>
                    <Grid.Row style={{backgroundColor: '#006491', paddingTop: '5px', paddingBottom: '5px'}}>
                        <Grid.Column style={{display: 'flex', alignItems: 'center'}}>
                            <a style={{
                                color: 'lightgrey',
                                marginRight: 'auto',
                                textDecoration: 'none'
                            }} href='mailto:kontakt@openknowledge.de'><Icon name='mail' />Kontakt</a>
                            <a style={{
                                color: 'lightgrey',
                                marginLeft: 'auto',
                                marginRight: 'auto',
                                textDecoration: 'none'
                            }} href='https://www.openknowledge.de' rel='noopener noreferrer'>OPEN KNOWLEDGE GmbH</a>
                            <a style={{
                                color: 'lightgrey',
                                marginLeft: 'auto',
                                textDecoration: 'none'
                            }} href='https://www.openknowledge.de/blog/' rel='noopener noreferrer' target='_blank'><Icon name='book' />Blog</a>
                        </Grid.Column>
                    </Grid.Row>
                </Grid>
            </Container>
        );
    }
}

export default App;
