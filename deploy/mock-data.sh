#!/usr/bin/env bash

set -eu

CA=$LOCALTMP/fake.ca
echo "-----BEGIN CERTIFICATE-----\nfake-cert\n-----END CERTIFICATE-----" > $CA

suffix=x; cluster=cluster-$suffix; tenant=$cluster-tenant; tenant_prefix=t$suffix; user=$tenant-user
$MONOCTL --monoconfig $MONOSKOPECONFIG create cluster $cluster -a https://$cluster.monoskope.dev -c $CA 2>/dev/null || true
cid=$($MONOCTL --monoconfig $MONOSKOPECONFIG get clusters --wide | grep $cluster | awk '{print $1}')

$MONOCTL --monoconfig $MONOSKOPECONFIG create tenant $tenant $tenant_prefix 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG grant cluster-access $tenant $cluster 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r oncall -s system -e $cid $user@monoskope.dev 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user-2@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user-2@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r admin -s system -e $cid $user@monoskope.dev 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user-3@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user-3@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG delete user $user-3@monoskope.dev 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create tenant $tenant-revoked $tenant_prefix-r 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG grant cluster-access $tenant-revoked $cluster 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG revoke cluster-access $tenant-revoked $cluster 2>/dev/null || true


suffix=y; cluster=cluster-$suffix; tenant=$cluster-tenant; tenant_prefix=t$suffix; user=$tenant-user
$MONOCTL --monoconfig $MONOSKOPECONFIG create cluster $cluster -a https://$cluster.monoskope.dev -c $CA 2>/dev/null || true
cid=$($MONOCTL --monoconfig $MONOSKOPECONFIG get clusters --wide | grep $cluster | awk '{print $1}')

$MONOCTL --monoconfig $MONOSKOPECONFIG create tenant $tenant $tenant_prefix 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG grant cluster-access $tenant $cluster 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user@monoskope.dev 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user-2@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user@monoskope.dev 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user-3@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user@monoskope.dev 2>/dev/null || true

$MONOCTL --monoconfig $MONOSKOPECONFIG create user $user-4@monoskope.dev 2>/dev/null || true
$MONOCTL --monoconfig $MONOSKOPECONFIG create rolebinding -r user -s tenant -e $tenant $user@monoskope.dev 2>/dev/null || true

echo "done"